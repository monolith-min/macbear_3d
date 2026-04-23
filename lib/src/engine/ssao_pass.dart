import '../m3_internal.dart';

import '../shaders_gen/SSAODepthNormal.es3.frag.g.dart';
import '../shaders_gen/SSAODepthNormal.es3.vert.g.dart';
import '../shaders_gen/SSAO.es3.frag.g.dart';
import '../shaders_gen/SSAO.es3.vert.g.dart';
import '../shaders_gen/SSAOBlur.es3.frag.g.dart';
import '../shaders_gen/SSAOBlur.es3.vert.g.dart';
import '../shaders_gen/glsl/Skinning.es3.vert.g.dart';

/// SSAO (Screen-Space Ambient Occlusion) multi-pass renderer.
///
/// Manages G-Buffer, SSAO calculation, and blur passes to produce
/// an AO texture that can be sampled during the main lighting pass.
class M3SSAOPass {
  RenderingContext get gl => M3AppEngine.instance.renderEngine.gl;

  late M3FramebufferColorDepth _gBuffer;
  late M3FramebufferColorDepth _aoBuffer;
  late M3FramebufferColorDepth _blurBuffer;

  late M3Program _prepassProgram;
  late M3Program _ssaoProgram;
  late M3Program _blurProgram;

  late M3Texture _texGBuffer;
  late M3Texture _texAO;
  late M3Texture _texBlur;
  late M3Texture _texNoise;

  // Uniform locations for prepass
  late UniformLocation _prepassViewMatrix;
  late UniformLocation _prepassNear;
  late UniformLocation _prepassFar;

  // Uniform locations for SSAO
  late UniformLocation _ssaoSamplerNoise;
  late UniformLocation _ssaoSamples;
  late UniformLocation _ssaoProjection;
  late UniformLocation _ssaoNoiseScale;
  late UniformLocation _ssaoRadius;
  late UniformLocation _ssaoBias;
  late UniformLocation _ssaoNear;
  late UniformLocation _ssaoFar;

  // Uniform locations for blur
  late UniformLocation _blurTexelSize;

  // SSAO kernel samples
  final List<Vector3> _kernel = [];

  int _width = 1;
  int _height = 1;

  // SSAO parameters
  double radius = 0.5;
  double bias = 0.025;

  M3SSAOPass(int width, int height) {
    _width = width;
    _height = height;

    debugPrint('M3SSAOPass: creating ($width x $height)');

    // Create framebuffers
    _gBuffer = M3FramebufferColorDepth(width, height);
    _aoBuffer = M3FramebufferColorDepth(width, height);
    _blurBuffer = M3FramebufferColorDepth(width, height);

    // Wrap textures
    _texGBuffer = M3Texture.fromWebGLTexture(_gBuffer.colorTexture, texW: width, texH: height);
    _texAO = M3Texture.fromWebGLTexture(_aoBuffer.colorTexture, texW: width, texH: height);
    _texBlur = M3Texture.fromWebGLTexture(_blurBuffer.colorTexture, texW: width, texH: height);

    // Create programs
    final skinNormalVert = '#define ENABLE_NORMAL \n$Skinning_vert';
    _prepassProgram = M3Program(skinNormalVert + SSAODepthNormal_vert, SSAODepthNormal_frag);
    _ssaoProgram = M3Program(SSAO_vert, SSAO_frag);
    _blurProgram = M3Program(SSAOBlur_vert, SSAOBlur_frag);

    // Get uniform locations
    _initPrepassLocations();
    _initSSAOLocations();
    _initBlurLocations();

    // Generate kernel and noise
    _generateKernel();
    _generateNoiseTexture();

    debugPrint('M3SSAOPass: initialized');
  }

  void _initPrepassLocations() {
    gl.useProgram(_prepassProgram.program);
    _prepassViewMatrix = gl.getUniformLocation(_prepassProgram.program, 'ViewMatrix');
    _prepassNear = gl.getUniformLocation(_prepassProgram.program, 'uNear');
    _prepassFar = gl.getUniformLocation(_prepassProgram.program, 'uFar');
  }

  void _initSSAOLocations() {
    gl.useProgram(_ssaoProgram.program);
    _ssaoSamplerNoise = gl.getUniformLocation(_ssaoProgram.program, 'SamplerNoise');
    _ssaoSamples = gl.getUniformLocation(_ssaoProgram.program, 'uSamples');
    _ssaoProjection = gl.getUniformLocation(_ssaoProgram.program, 'uProjection');
    _ssaoNoiseScale = gl.getUniformLocation(_ssaoProgram.program, 'uNoiseScale');
    _ssaoRadius = gl.getUniformLocation(_ssaoProgram.program, 'uRadius');
    _ssaoBias = gl.getUniformLocation(_ssaoProgram.program, 'uBias');
    _ssaoNear = gl.getUniformLocation(_ssaoProgram.program, 'uNear');
    _ssaoFar = gl.getUniformLocation(_ssaoProgram.program, 'uFar');

    // Bind texture units
    if (M3Program.isLocationValid(_ssaoProgram.uniformSamplerDiffuse)) {
      gl.uniform1i(_ssaoProgram.uniformSamplerDiffuse, 0); // G-Buffer on TEXTURE0
    }
    if (M3Program.isLocationValid(_ssaoSamplerNoise)) {
      gl.uniform1i(_ssaoSamplerNoise, 1); // Noise on TEXTURE1
    }
  }

  void _initBlurLocations() {
    gl.useProgram(_blurProgram.program);
    _blurTexelSize = gl.getUniformLocation(_blurProgram.program, 'uTexelSize');
  }

  void _generateKernel() {
    final rng = Random(42);
    _kernel.clear();
    for (int i = 0; i < 16; i++) {
      // Random point in hemisphere (z > 0)
      final sample = Vector3(
        rng.nextDouble() * 2.0 - 1.0,
        rng.nextDouble() * 2.0 - 1.0,
        rng.nextDouble(), // z in [0, 1] for hemisphere
      );
      sample.normalize();
      // Scale so more samples are closer to the origin
      double scale = i / 16.0;
      scale = 0.1 + scale * scale * 0.9; // lerp(0.1, 1.0, scale*scale)
      sample.scale(scale);
      _kernel.add(sample);
    }
  }

  void _generateNoiseTexture() {
    final rng = Random(42);
    // 4x4 noise texture with random rotation vectors in tangent space
    // Use RGBA8/UNSIGNED_BYTE for compatibility. Encode [-1,1] as [0,255].
    final noiseData = Uint8List(4 * 4 * 4); // RGBA
    for (int i = 0; i < 16; i++) {
      // Random rotation in tangent plane: x,y in [-1,1], z=0
      final x = rng.nextDouble() * 2.0 - 1.0;
      final y = rng.nextDouble() * 2.0 - 1.0;
      noiseData[i * 4] = ((x * 0.5 + 0.5) * 255).round().clamp(0, 255);
      noiseData[i * 4 + 1] = ((y * 0.5 + 0.5) * 255).round().clamp(0, 255);
      noiseData[i * 4 + 2] = 128; // z = 0.0 → 0.5 * 255
      noiseData[i * 4 + 3] = 255; // alpha = 1.0
    }

    final noiseTex = gl.createTexture();
    gl.bindTexture(WebGL.TEXTURE_2D, noiseTex);
    gl.texImage2D(
      WebGL.TEXTURE_2D, 0, WebGL.RGBA8,
      4, 4, 0,
      WebGL.RGBA, WebGL.UNSIGNED_BYTE, Uint8Array.fromList(noiseData),
    );
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, WebGL.NEAREST);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, WebGL.NEAREST);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_S, WebGL.REPEAT);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_WRAP_T, WebGL.REPEAT);

    _texNoise = M3Texture.fromWebGLTexture(noiseTex, texW: 4, texH: 4);
  }

  /// The final blurred AO texture, ready to sample in the lighting pass.
  M3Texture get aoTexture => _texBlur;

  /// Render depth/normal prepass into G-Buffer.
  void renderPrepass(M3Scene scene, M3Camera camera) {
    _gBuffer.bind();

    gl.clearColor(0.5, 0.5, 1.0, 0.0); // default normal = (0,0,1), depth = 0
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

    gl.frontFace(WebGL.CCW);
    gl.enable(WebGL.CULL_FACE);
    gl.enable(WebGL.DEPTH_TEST);
    gl.depthMask(true);
    gl.depthFunc(WebGL.LEQUAL);
    gl.disable(WebGL.BLEND);

    gl.useProgram(_prepassProgram.program);

    // Set view matrix and near/far
    if (M3Program.isLocationValid(_prepassViewMatrix)) {
      gl.uniformMatrix4fv(_prepassViewMatrix, false, camera.viewMatrix.storage);
    }
    if (M3Program.isLocationValid(_prepassNear)) {
      gl.uniform1f(_prepassNear, camera.nearClip);
    }
    if (M3Program.isLocationValid(_prepassFar)) {
      gl.uniform1f(_prepassFar, camera.farClip);
    }

    // Render all visible entities
    for (final entity in scene.entities) {
      if (entity.mesh == null || !entity.visible) continue;

      final mesh = entity.mesh!;
      final modelMatrix = mesh.skin != null ? entity.matrix : entity.matrix * mesh.initMatrix;

      _prepassProgram.setMatrices(camera, modelMatrix);
      _prepassProgram.setMaterial(mesh.mtr, entity.color);
      _prepassProgram.setSkinning(mesh.skin);

      mesh.geom.draw(_prepassProgram, bSolid: true);
    }

    gl.enable(WebGL.BLEND);
  }

  /// Run the SSAO calculation pass (full-screen quad).
  void renderSSAO(M3Camera camera) {
    _aoBuffer.bind();
    gl.clearColor(1.0, 1.0, 1.0, 1.0);
    gl.clear(WebGL.COLOR_BUFFER_BIT);

    gl.disable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.CULL_FACE);
    gl.disable(WebGL.BLEND);

    gl.useProgram(_ssaoProgram.program);

    // Bind G-Buffer texture to TEXTURE0
    gl.activeTexture(WebGL.TEXTURE0);
    _texGBuffer.bind();

    // Bind noise texture to TEXTURE1
    gl.activeTexture(WebGL.TEXTURE1);
    _texNoise.bind();
    gl.activeTexture(WebGL.TEXTURE0);

    // Set uniforms
    if (M3Program.isLocationValid(_ssaoProjection)) {
      gl.uniformMatrix4fv(_ssaoProjection, false, camera.projectionMatrix.storage);
    }
    if (M3Program.isLocationValid(_ssaoNoiseScale)) {
      gl.uniform2f(_ssaoNoiseScale, _width / 4.0, _height / 4.0);
    }
    if (M3Program.isLocationValid(_ssaoRadius)) {
      gl.uniform1f(_ssaoRadius, radius);
    }
    if (M3Program.isLocationValid(_ssaoBias)) {
      gl.uniform1f(_ssaoBias, bias);
    }
    if (M3Program.isLocationValid(_ssaoNear)) {
      gl.uniform1f(_ssaoNear, camera.nearClip);
    }
    if (M3Program.isLocationValid(_ssaoFar)) {
      gl.uniform1f(_ssaoFar, camera.farClip);
    }

    // Upload kernel samples
    if (M3Program.isLocationValid(_ssaoSamples)) {
      final kernelData = Float32List(16 * 3);
      for (int i = 0; i < 16; i++) {
        kernelData[i * 3] = _kernel[i].x;
        kernelData[i * 3 + 1] = _kernel[i].y;
        kernelData[i * 3 + 2] = _kernel[i].z;
      }
      gl.uniform3fv(_ssaoSamples, kernelData);
    }

    // Draw full-screen quad
    _drawFullScreenQuad(_ssaoProgram);
  }

  /// Blur the raw SSAO output.
  void renderBlur() {
    _blurBuffer.bind();
    gl.clearColor(1.0, 1.0, 1.0, 1.0);
    gl.clear(WebGL.COLOR_BUFFER_BIT);

    gl.disable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.CULL_FACE);
    gl.disable(WebGL.BLEND);

    gl.useProgram(_blurProgram.program);

    // Bind raw SSAO texture
    gl.activeTexture(WebGL.TEXTURE0);
    _texAO.bind();

    if (M3Program.isLocationValid(_blurTexelSize)) {
      gl.uniform2f(_blurTexelSize, 1.0 / _width, 1.0 / _height);
    }

    _drawFullScreenQuad(_blurProgram);
  }

  /// Draw a full-screen quad using the Rect program's vertex layout.
  void _drawFullScreenQuad(M3Program prog) {
    // Set ortho projection so the unit rect [0,1] maps to full screen
    final ortho = Matrix4.identity();
    // Map [0,1] x [0,1] quad to [-1,1] NDC
    ortho.setEntry(0, 0, 2.0);
    ortho.setEntry(1, 1, 2.0);
    ortho.setEntry(0, 3, -1.0);
    ortho.setEntry(1, 3, -1.0);

    prog.setProjectionMatrix(ortho);
    prog.setModelMatrix(Matrix4.identity());

    gl.enableVertexAttribArray(prog.attribVertex.id);
    gl.enableVertexAttribArray(prog.attribUV.id);

    M3Resources.rectUnit.draw();

    gl.disableVertexAttribArray(prog.attribVertex.id);
    gl.disableVertexAttribArray(prog.attribUV.id);
  }

  void dispose() {
    _gBuffer.dispose();
    _aoBuffer.dispose();
    _blurBuffer.dispose();
    _prepassProgram.dispose();
    _ssaoProgram.dispose();
    _blurProgram.dispose();
    _texNoise.dispose();
  }
}
