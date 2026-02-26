// Macbear3D engine
import '../../macbear_3d.dart';

class M3ReflectionProbe {
  Vector3 position;
  final _camCapture = M3Camera();
  M3Entity? _captureEntity; // ignore capture entity

  int texSize = 128;
  M3Texture? texCubemap;
  M3Framebuffer? _fbo;

  M3ReflectionProbe({required this.position, this.texSize = 128}) {
    // Temporary camera with 90 degree FOV
    _camCapture.csmCount = 0;
    _camCapture.setViewport(0, 0, texSize, texSize, fovy: 90.0, near: 0.1, far: 200.0);
    _fbo ??= M3Framebuffer(texSize, texSize, useDepthTexture: false);
    texCubemap ??= M3Texture.createEmptyCubemap(texSize);
  }

  void dispose() {
    _fbo?.dispose();
    _fbo = null;
    texCubemap?.dispose();
    texCubemap = null;
  }

  /// Capture the scene from the probe's position into a cubemap texture.
  void capture(M3Scene scene) {
    final renderEngine = M3AppEngine.instance.renderEngine;
    final gl = renderEngine.gl;

    // Cache framebuffer and empty cubemap if needed

    final targets = [
      Vector3(1, 0, 0),
      Vector3(-1, 0, 0),
      Vector3(0, 1, 0),
      Vector3(0, -1, 0),
      Vector3(0, 0, 1),
      Vector3(0, 0, -1),
    ];
    final ups = [
      Vector3(0, -1, 0),
      Vector3(0, -1, 0),
      Vector3(0, 0, 1),
      Vector3(0, 0, -1),
      Vector3(0, -1, 0),
      Vector3(0, -1, 0),
    ];
    final faces = [
      WebGL.TEXTURE_CUBE_MAP_POSITIVE_X,
      WebGL.TEXTURE_CUBE_MAP_NEGATIVE_X,
      WebGL.TEXTURE_CUBE_MAP_POSITIVE_Y,
      WebGL.TEXTURE_CUBE_MAP_NEGATIVE_Y,
      WebGL.TEXTURE_CUBE_MAP_POSITIVE_Z,
      WebGL.TEXTURE_CUBE_MAP_NEGATIVE_Z,
    ];

    final prog = M3Resources.programTexture!;
    prog.applyLight(scene.light);

    for (int i = 0; i < 6; i++) {
      // Bind face
      _fbo!.bindFace(faces[i], texCubemap!.glTexture);

      // Clear
      gl.clearColor(0, 0, 0, 1);
      gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

      // Setup camera
      _camCapture.setLookat(position, position + targets[i], ups[i]);

      // Render skybox
      if (scene.skybox != null) {
        scene.skybox!.drawSkybox(_camCapture);
      }
      // set default GL state
      gl.frontFace(WebGL.CCW);
      gl.enable(WebGL.DEPTH_TEST);
      gl.enable(WebGL.CULL_FACE);
      gl.depthMask(true);
      gl.depthFunc(WebGL.LEQUAL);

      gl.enable(WebGL.BLEND);
      gl.blendFunc(WebGL.SRC_ALPHA, WebGL.ONE_MINUS_SRC_ALPHA); // WebGL.ONE

      // ignore entity
      if (_captureEntity != null) {
        scene.entities.remove(_captureEntity!);
      }
      // Render scene
      scene.render(prog, _camCapture, bSolid: true);

      if (_captureEntity != null) {
        scene.entities.add(_captureEntity!);
      }
    }

    // Restore state
    renderEngine.bindDefaultFramebuffer();
  }
}
