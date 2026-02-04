// Macbear3D engine
import '../../macbear_3d.dart';

import 'shadow_map.dart';

part 'render_options.dart';

/// The WebGL rendering engine that manages shaders, framebuffers, and scene rendering.
///
/// Handles shader program creation, shadow mapping, 2D overlay rendering, and viewport management.
class M3RenderEngine {
  late RenderingContext gl;

  // shadow map
  M3ShadowMap? _shadowMap;
  M3ShadowMap? get shadowMap => _shadowMap;

  // for ortho-matrix to project to 2D screen
  final _projection2D = M3Projection();

  // render options, statistics
  final M3RenderOptions options = M3RenderOptions();
  final M3RenderStats stats = M3RenderStats();

  // constructor
  M3RenderEngine() {
    debugPrint("--- M3RenderEngine constructor ---");
  }

  void dispose() {
    _shadowMap?.dispose();
  }

  void getExtensions() {
    // 取得 WebGL context
    // final a = WebGLParameter(WebGL.RENDERER);
    // final b = WebGLParameter(WebGL.VENDOR);
    // final c = WebGLParameter(WebGL.VERSION);
    // 取出基本資訊
    // final renderer = gl.getParameter(WebGL.RENDERER);
    // final vendor = gl.getParameter(WebGL.VENDOR);
    // final version = gl.getParameter(WebGL.VERSION);
    // final shadingLang = gl.getParameter(WebGL.SHADING_LANGUAGE_VERSION);
    // print('GL_VENDOR: $vendor');
    // print('GL_RENDERER: $renderer');
    // print('GL_VERSION: $version');
    // print('GL_SHADING_LANGUAGE_VERSION: $shadingLang');

    List<int> paramKeys = [
      WebGL.MAX_TEXTURE_IMAGE_UNITS,
      WebGL.MAX_VERTEX_TEXTURE_IMAGE_UNITS,
      WebGL.MAX_TEXTURE_SIZE,
      WebGL.MAX_CUBE_MAP_TEXTURE_SIZE,
      WebGL.MAX_VERTEX_ATTRIBS,
      WebGL.MAX_VERTEX_UNIFORM_VECTORS,
      WebGL.MAX_VARYING_VECTORS,
      WebGL.MAX_FRAGMENT_UNIFORM_VECTORS,
      WebGL.MAX_SAMPLES,
      WebGL.MAX_COMBINED_TEXTURE_IMAGE_UNITS,
      WebGL.SCISSOR_BOX,
      WebGL.VIEWPORT,
      WebGL.MAX_TEXTURE_MAX_ANISOTROPY_EXT,
      WebGL.MAX_UNIFORM_BUFFER_BINDINGS,
    ];
    for (final key in paramKeys) {
      int val = gl.getParameter(key);
      debugPrint("GL Int[$key] = $val");
    }
    for (int i = 0; i < 150; i++) {
      final s0 = gl.getStringi(WebGL.EXTENSIONS, i);
      debugPrint("GL [$i] = $s0");
      if (s0 == 'unnamed') {
        break;
      }
    }
  }

  void createShadowMap({int width = 1024, int height = 1024}) {
    _shadowMap ??= M3ShadowMap(width, height);
  }

  void bindDefaultFramebuffer() {
    final engine = M3AppEngine.instance;
    final pixelW = (engine.appWidth * engine.devicePixelRatio).toInt();
    final pixelH = (engine.appHeight * engine.devicePixelRatio).toInt();
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, engine.mainFbo);
    gl.viewport(0, 0, pixelW, pixelH);
  }

  void setViewport(int width, int height, double dpr) {
    debugPrint("=== Viewport ($width x $height) dpr: $dpr ===");

    final pixelW = (width * dpr).toInt();
    final pixelH = (height * dpr).toInt();
    gl.viewport(0, 0, pixelW, pixelH);
    // camera viewport by pixel size
    M3AppEngine.instance.activeScene?.camera.setViewport(0, 0, pixelW, pixelH);

    // projection 2D viewport by screen size
    _projection2D.setViewport(0, height, width, -height, fovy: 0, near: -1.0, far: 1.0);
    gl.lineWidth(dpr * 2.0);
  }

  void renderScene(M3Scene scene) {
    stats.reset();
    stats.frames++;

    // draw skybox
    if (scene.skybox != null) {
      scene.skybox!.drawSkybox(scene.camera);
    }

    // set default GL state
    gl.frontFace(WebGL.CCW);
    gl.enable(WebGL.DEPTH_TEST);
    gl.enable(WebGL.CULL_FACE);
    gl.depthMask(true);
    gl.depthFunc(WebGL.LEQUAL);

    gl.enable(WebGL.BLEND);
    gl.blendFunc(WebGL.SRC_ALPHA, WebGL.ONE_MINUS_SRC_ALPHA); // WebGL.ONE

    if (!options.debug.wireframe) {
      M3ProgramLighting progLight = M3Resources.programTexture!; // texture shader
      // M3ProgramLighting progLight = M3Resources.programSimpleLighting!; // texture shader
      // Render Shadow Map
      if (options.shadows && _shadowMap != null) {
        _shadowMap!.renderDepthPass(scene, scene.light);

        M3ProgramShadow progShadow = M3Resources.programShadowmap!;
        // cascaded shadow mapping
        if (scene.light.cascades.isNotEmpty) {
          progShadow = M3Resources.programShadowCSM!;
        }
        progLight = progShadow;
        // bind shadowmap texture
        gl.useProgram(progShadow.program);
        progShadow.bindShadow(_shadowMap!.depthTexture);
      }

      progLight.applyLight(scene.light);
      // solid
      scene.render(progLight, scene.camera, bSolid: true);

      // reflection pass (only if not using single-pass IBL)
      if (scene.skybox != null && !options.shader.ibl) {
        scene.renderReflection();
      }
    } else {
      // wireframe
      scene.render(M3Resources.programSimple!, scene.camera, bSolid: false);
    }

    // draw Helper
    if (options.debug.showHelpers) {
      scene.renderHelper();
    }
  }

  void render2D() {
    // ortho-param: left, right, top, bottom, near, far (flip Y-axis by swap top/bottom)
    gl.disable(WebGL.DEPTH_TEST);
    gl.disable(WebGL.CULL_FACE);
    gl.enable(WebGL.BLEND);
    gl.blendFunc(WebGL.SRC_ALPHA, WebGL.ONE_MINUS_SRC_ALPHA);

    final prog2D = M3Resources.programRectangle!;
    gl.useProgram(prog2D.program);
    prog2D.setProjectionMatrix(_projection2D.projectionMatrix);

    gl.enableVertexAttribArray(prog2D.attribVertex.id);
    gl.enableVertexAttribArray(prog2D.attribUV.id);

    // draw rectangle full-screen
    final engine = M3AppEngine.instance;
    if (engine.activeScene != null) {
      engine.activeScene!.render2D();
    }

    // 2D helper
    if (options.debug.showHelpers) {
      if (options.shadows && _shadowMap != null) {
        final width = 200 / _shadowMap!.mapH * _shadowMap!.mapW;
        _shadowMap!.drawDebugDepth(10, engine.appHeight - 210, width, 200);
      }

      prog2D.setModelMatrix(Matrix4.identity());

      // draw test: triangle, line, touches
      M3Shape2D.drawTouches(engine.touchManager);
    }
    // Render Statistics
    Matrix4 matStats = Matrix4.identity();
    if (options.debug.showStats) {
      matStats.setTranslation(Vector3(M3AppEngine.instance.appWidth - 50, 50, 0));
      matStats.scaleByVector3(Vector3.all(0.5));
      final fpsText = engine.fps.toStringAsFixed(2);
      M3Resources.text2D.drawText(fpsText, matStats, color: Vector4(0, 1, 0, 1));

      matStats.setTranslation(Vector3(M3AppEngine.instance.appWidth - 90, 66, 0));
      matStats.scaleByVector3(Vector3.all(0.9));
      // Render Stats
      M3Resources.text2D.drawText(stats.toString(), matStats, color: Vector4(1, 1, 1, 1));

      if (engine.activeScene != null) {
        final scene = engine.activeScene!;

        final shadowText =
            '''
shadow:${options.shadows ? 'Y' : 'N'}
$shadowMap
csm=${scene.camera.csmCount}''';
        matStats.setTranslation(Vector3(M3AppEngine.instance.appWidth - 90, 150, 0));
        // Shadow Info
        M3Resources.text2D.drawText(shadowText, matStats, color: Vector4(1, 1, 0, 1));
      }
    }

    // Physics Statistics
    final physicsWorld = M3AppEngine.instance.physicsEngine.world;
    if (physicsWorld != null) {
      physicsWorld.isStat = options.debug.showPhysicsStats;
      if (options.debug.showPhysicsStats) {
        final physicsInfo = physicsWorld.getInfo();
        matStats.setTranslation(Vector3(10, 300, 0));
        M3Resources.text2D.drawText(physicsInfo, matStats, color: Vector4(1, 0, 1, 1));
      }
    }

    gl.disableVertexAttribArray(prog2D.attribVertex.id);
    gl.disableVertexAttribArray(prog2D.attribUV.id);
  }
}
