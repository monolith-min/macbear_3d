import '../m3_internal.dart';

import '../shaders_gen/BloomBright.es3.frag.g.dart';
import '../shaders_gen/BloomBright.es3.vert.g.dart';
import '../shaders_gen/BloomBlur.es3.frag.g.dart';
import '../shaders_gen/BloomBlur.es3.vert.g.dart';
import '../shaders_gen/BloomComposite.es3.frag.g.dart';
import '../shaders_gen/BloomComposite.es3.vert.g.dart';

/// Bloom post-processing pass.
///
/// Renders the scene to an offscreen FBO, extracts bright areas,
/// applies two-pass Gaussian blur, and composites the bloom
/// additively onto the original scene.
class M3BloomPass {
  RenderingContext get gl => M3AppEngine.instance.renderEngine.gl;

  // FBOs
  late M3FramebufferColorDepth _sceneFbo; // full-res scene capture
  late M3FramebufferColorDepth _brightFbo; // half-res bright extraction
  late M3FramebufferColorDepth _blurPingFbo; // half-res blur ping
  late M3FramebufferColorDepth _blurPongFbo; // half-res blur pong

  // Wrapped textures
  late M3Texture _texScene;
  late M3Texture _texBright;
  late M3Texture _texBlurPing;
  late M3Texture _texBlurPong;

  // Shader programs
  late M3Program _brightProgram;
  late M3Program _blurProgram;
  late M3Program _compositeProgram;

  // Uniform locations: bright pass
  late UniformLocation _brightThreshold;

  // Uniform locations: blur
  late UniformLocation _blurDirection;

  // Uniform locations: composite
  late UniformLocation _compositeSamplerBloom;
  late UniformLocation _compositeIntensity;

  int _width = 1;
  int _height = 1;
  int _halfW = 1;
  int _halfH = 1;

  // Adjustable parameters
  double threshold = 0.7;
  double intensity = 1.0;
  int blurIterations = 2; // number of blur ping-pong iterations

  M3BloomPass(int width, int height) {
    _width = width;
    _height = height;
    _halfW = (width / 2).ceil().clamp(1, width);
    _halfH = (height / 2).ceil().clamp(1, height);

    debugPrint('M3BloomPass: creating ($width x $height), blur: $_halfW x $_halfH');

    // Scene FBO: full resolution with depth
    _sceneFbo = M3FramebufferColorDepth(_width, _height);
    _texScene = M3Texture.fromWebGLTexture(_sceneFbo.colorTexture, texW: _width, texH: _height);

    // Use LINEAR filtering for scene texture (better downsampling)
    gl.bindTexture(WebGL.TEXTURE_2D, _sceneFbo.colorTexture);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, WebGL.LINEAR);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, WebGL.LINEAR);

    // Bright pass FBO: half resolution
    _brightFbo = M3FramebufferColorDepth(_halfW, _halfH);
    _texBright = M3Texture.fromWebGLTexture(_brightFbo.colorTexture, texW: _halfW, texH: _halfH);

    gl.bindTexture(WebGL.TEXTURE_2D, _brightFbo.colorTexture);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, WebGL.LINEAR);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, WebGL.LINEAR);

    // Blur ping-pong FBOs: half resolution
    _blurPingFbo = M3FramebufferColorDepth(_halfW, _halfH);
    _texBlurPing = M3Texture.fromWebGLTexture(_blurPingFbo.colorTexture, texW: _halfW, texH: _halfH);

    gl.bindTexture(WebGL.TEXTURE_2D, _blurPingFbo.colorTexture);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, WebGL.LINEAR);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, WebGL.LINEAR);

    _blurPongFbo = M3FramebufferColorDepth(_halfW, _halfH);
    _texBlurPong = M3Texture.fromWebGLTexture(_blurPongFbo.colorTexture, texW: _halfW, texH: _halfH);

    gl.bindTexture(WebGL.TEXTURE_2D, _blurPongFbo.colorTexture);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MAG_FILTER, WebGL.LINEAR);
    gl.texParameteri(WebGL.TEXTURE_2D, WebGL.TEXTURE_MIN_FILTER, WebGL.LINEAR);

    // Create shader programs
    _brightProgram = M3Program(BloomBright_vert, BloomBright_frag);
    _blurProgram = M3Program(BloomBlur_vert, BloomBlur_frag);
    _compositeProgram = M3Program(BloomComposite_vert, BloomComposite_frag);

    _initLocations();

    debugPrint('M3BloomPass: initialized');
  }

  void _initLocations() {
    // Bright pass
    gl.useProgram(_brightProgram.program);
    _brightThreshold = gl.getUniformLocation(_brightProgram.program, 'uThreshold');

    // Blur
    gl.useProgram(_blurProgram.program);
    _blurDirection = gl.getUniformLocation(_blurProgram.program, 'uDirection');

    // Composite
    gl.useProgram(_compositeProgram.program);
    _compositeSamplerBloom = gl.getUniformLocation(_compositeProgram.program, 'SamplerBloom');
    _compositeIntensity = gl.getUniformLocation(_compositeProgram.program, 'uBloomIntensity');

    // Bind bloom sampler to TEXTURE1
    if (M3Program.isLocationValid(_compositeSamplerBloom)) {
      gl.uniform1i(_compositeSamplerBloom, 1);
    }
  }

  /// The scene FBO — bind this before rendering the scene.
  M3FramebufferColorDepth get sceneFbo => _sceneFbo;

  /// Bind the scene FBO for scene rendering.
  void bindSceneFbo() {
    _sceneFbo.bind();
    gl.clearColor(0.0, 0.0, 0.0, 0.0);
    gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);
  }

  /// Extract bright areas from the scene texture.
  void renderBrightPass() {
    _brightFbo.bind();
    gl.clearColor(0.0, 0.0, 0.0, 1.0);
    gl.clear(WebGL.COLOR_BUFFER_BIT);

    gl.disable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.CULL_FACE);
    gl.disable(WebGL.BLEND);

    gl.useProgram(_brightProgram.program);

    // Bind scene texture
    gl.activeTexture(WebGL.TEXTURE0);
    _texScene.bind();

    if (M3Program.isLocationValid(_brightThreshold)) {
      gl.uniform1f(_brightThreshold, threshold);
    }

    _drawFullScreenQuad(_brightProgram);
  }

  /// Apply separable Gaussian blur (ping-pong between two FBOs).
  void renderBlur() {
    gl.disable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.CULL_FACE);
    gl.disable(WebGL.BLEND);

    gl.useProgram(_blurProgram.program);

    // First iteration reads from bright, subsequent read from pong
    M3Texture inputTex = _texBright;

    for (int i = 0; i < blurIterations; i++) {
      // Horizontal blur → ping
      _blurPingFbo.bind();
      gl.clear(WebGL.COLOR_BUFFER_BIT);
      gl.activeTexture(WebGL.TEXTURE0);
      inputTex.bind();

      if (M3Program.isLocationValid(_blurDirection)) {
        gl.uniform2f(_blurDirection, 1.0 / _halfW, 0.0);
      }
      _drawFullScreenQuad(_blurProgram);

      // Vertical blur → pong
      _blurPongFbo.bind();
      gl.clear(WebGL.COLOR_BUFFER_BIT);
      gl.activeTexture(WebGL.TEXTURE0);
      _texBlurPing.bind();

      if (M3Program.isLocationValid(_blurDirection)) {
        gl.uniform2f(_blurDirection, 0.0, 1.0 / _halfH);
      }
      _drawFullScreenQuad(_blurProgram);

      // Next iteration reads from pong
      inputTex = _texBlurPong;
    }
  }

  /// Composite the scene + bloom to the current framebuffer (default FBO).
  void renderComposite() {
    gl.disable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.CULL_FACE);
    gl.disable(WebGL.BLEND);

    gl.useProgram(_compositeProgram.program);

    // TEXTURE0: original scene
    gl.activeTexture(WebGL.TEXTURE0);
    _texScene.bind();

    // TEXTURE1: blurred bloom
    gl.activeTexture(WebGL.TEXTURE1);
    _texBlurPong.bind();
    gl.activeTexture(WebGL.TEXTURE0);

    if (M3Program.isLocationValid(_compositeIntensity)) {
      gl.uniform1f(_compositeIntensity, intensity);
    }

    _drawFullScreenQuad(_compositeProgram);
  }

  void _drawFullScreenQuad(M3Program prog) {
    final ortho = Matrix4.identity();
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
    _sceneFbo.dispose();
    _brightFbo.dispose();
    _blurPingFbo.dispose();
    _blurPongFbo.dispose();
    _brightProgram.dispose();
    _blurProgram.dispose();
    _compositeProgram.dispose();
  }
}
