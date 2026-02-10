import 'package:flutter/widgets.dart' hide Matrix4;
import 'package:oimo_physics/oimo_physics.dart' as oimo;

// Macbear3D engine
import '../../macbear_3d.dart';

export 'camera.dart';
export 'entity.dart';
export 'light.dart';
export 'skybox.dart';

part 'sample_scene.dart';

/// Abstract base class for 3D scenes in the engine.
///
/// Manages entities, cameras, lights, physics integration, and provides
/// rendering methods for solid, wireframe, and 2D content.
abstract class M3Scene {
  RenderingContext get gl => M3AppEngine.instance.renderEngine.gl;
  M3InputController? inputController;

  final _light = M3Light();
  final _camera = M3Camera();
  List<M3Camera> cameras = [];

  M3Camera get camera => cameras[0];
  M3Light get light => _light;

  // physics entities
  final List<M3Entity> entities = [];

  M3Skybox? skybox;

  M3Scene() {
    cameras.add(_camera);
    inputController = M3CameraOrbitController(_camera);

    // camera lookat Origin
    _camera.setLookat(Vector3(10, 0, 0), Vector3.zero(), Vector3(0, 0, 1));
    _camera.setEuler(0, 0, 0, distance: 20);

    // sun light
    int halfView = 8;
    light.setViewport(-halfView, -halfView, halfView * 2, halfView * 2, fovy: 0, far: 50);
    light.setEuler(pi / 5, -pi / 3, 0, distance: 15); // rotate light
  }

  void dispose() {
    skybox?.dispose();
  }

  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  // load skybox, meshes, etc.
  Future<void> load() async {
    _isLoaded = true;
  }

  M3Entity addMesh(M3Mesh mesh, Vector3 position) {
    final entity = M3Entity();
    entity.mesh = mesh;
    entity.position = position;

    entities.add(entity);

    return entity;
  }

  void addEntity(M3Entity entity) {
    entities.add(entity);
  }

  double _totalTime = 0.0;
  double get totalTime => _totalTime;

  void savePhysicsStates() {
    for (final entity in entities) {
      entity.savePhysicsState();
    }
  }

  void update(double delta) {
    _totalTime += delta;

    for (final entity in entities) {
      // update animation
      entity.update(delta);

      // sync physics
      entity.syncFromPhysics();

      // update bounds
      entity.updateBounds();
    }
  }

  // render solid models
  void render(M3Program prog, M3Camera camera, {bool bSolid = true}) {
    // pre-draw
    gl.useProgram(prog.program);
    prog.applyCamera(camera);

    final shaderOptions = M3AppEngine.instance.renderEngine.options.shader;
    if (prog is M3ProgramLighting && shaderOptions.pbr && shaderOptions.ibl) {
      if (M3Program.isLocationValid(prog.uniformSamplerEnvironment)) {
        gl.activeTexture(WebGL.TEXTURE2);
        if (skybox != null) {
          skybox!.mtr.texDiffuse.bind();
        } else {
          M3Resources.texDefaultCube.bind();
        }
        gl.uniform1i(prog.uniformSamplerEnvironment, 2);
        gl.activeTexture(WebGL.TEXTURE0); // Reset for setMaterial
      }
    }

    final stats = M3AppEngine.instance.renderEngine.stats;
    for (final entity in entities) {
      if (entity.mesh == null) {
        continue;
      }

      final mesh = entity.mesh!;
      // culling
      if (!camera.isVisible(entity.worldBounding)) {
        if (stats.enabled) stats.culling++;
        continue;
      }

      prog.setMatrices(camera, entity.matrix);
      prog.setMaterial(mesh.mtr, entity.color);
      prog.setSkinning(mesh.skin);

      mesh.geom.draw(prog, bSolid: bSolid);

      // statistics
      if (stats.enabled) {
        stats.entities++;
        stats.vertices += mesh.geom.vertexCount;
        stats.triangles += mesh.geom.getTriangleCount(bSolid: bSolid);
      }
    }
  }

  void renderReflection() {
    M3ProgramEye prog = M3Resources.programSkyboxReflect!;
    gl.depthFunc(WebGL.EQUAL); // Match exactly from 1st pass
    gl.depthMask(false); // Don't write to depth buffer in additive pass
    gl.blendFunc(WebGL.ONE, WebGL.ONE); // Additive blending

    // pre-draw
    gl.useProgram(prog.program);
    prog.applyCamera(camera);

    for (final entity in entities) {
      // culling
      if (entity.mesh == null || !camera.isVisible(entity.worldBounding)) {
        continue;
      }

      final mesh = entity.mesh!;
      if (mesh.mtr.reflection <= 0) {
        continue;
      }

      Vector4 reflectColor = Vector4.all(mesh.mtr.reflection);

      prog.setMatrices(camera, entity.matrix);
      // Use mesh material for PBR properties (metallic, roughness, diffuse)
      prog.setMaterial(mesh.mtr, reflectColor);
      // Override SamplerDiffuse with skybox cubemap for reflection lookup
      gl.activeTexture(WebGL.TEXTURE0);
      skybox!.mtr.texDiffuse.bind();

      prog.setSkinning(mesh.skin);

      mesh.geom.draw(prog, bSolid: true);

      // statistics
      final stats = M3AppEngine.instance.renderEngine.stats;
      if (stats.enabled) stats.reflection++;
    }

    // Reset depth state
    gl.depthMask(true);
    gl.depthFunc(WebGL.LEQUAL);
  }

  // render helper: zero, camera, light, wireframe
  void renderHelper() {
    M3Program progSimple = M3Resources.programSimple!;

    // pre-draw
    gl.useProgram(progSimple.program);
    gl.uniform1i(progSimple.uniformBoneCount, 0);

    for (final entity in entities) {
      // culling
      if (entity.mesh == null || !camera.isVisible(entity.worldBounding)) continue;

      final mesh = entity.mesh!;

      Matrix4 matMesh = Matrix4.copy(entity.matrix);
      if (mesh.skin != null) {
        // matMesh = matMesh * mesh.skin!.jointNodes![0].worldMatrix;
      }

      // origin axis
      progSimple.setMatrices(camera, matMesh);
      // draw axis at object origin
      progSimple.setMaterial(mesh.mtr, Colors.red);
      M3Resources.debugAxis.draw(progSimple);

      // bounding sphere
      Sphere worldSphere = entity.worldBounding.sphere;
      if (worldSphere.radius > 0) {
        Matrix4 matSphere = Matrix4.identity();
        matSphere.translateByVector3(worldSphere.center);
        matSphere.scaleByVector3(Vector3.all(worldSphere.radius * 1.03));
        progSimple.setMaterial(mesh.mtr, Colors.magenta);
        progSimple.setMatrices(camera, matSphere);
        M3Resources.debugSphere.draw(progSimple);
      }
      // AABB
      final matAabb = Matrix4.identity();
      matAabb.translateByVector3(entity.worldBounding.aabb.center);
      Vector3 extents = (entity.worldBounding.aabb.max - entity.worldBounding.aabb.min) / 2;
      extents += Vector3.all(0.03);
      matAabb.scaleByVector3(extents);
      progSimple.setMaterial(mesh.mtr, Colors.lime);
      progSimple.setMatrices(camera, matAabb);
      M3Resources.debugFrustum.draw(progSimple, bSolid: false);
    }

    M3Material mtrHelper = M3Material();
    for (final cam in cameras) {
      progSimple.setMaterial(mtrHelper, Colors.skyBlue);
      cam.drawHelper(progSimple, camera);
    }

    progSimple.setMaterial(mtrHelper, Colors.yellow);
    light.drawHelper(progSimple, camera);
  }

  void render2D() {}

  /// Build scene-specific UI controls.
  Widget? buildUI(BuildContext context) => null;

  /// Capture a cubemap texture from a specific position in the scene.
  Future<M3Texture> captureCubemap(Vector3 position, {int size = 512, bool bSolid = true}) async {
    final renderEngine = M3AppEngine.instance.renderEngine;
    final gl = renderEngine.gl;

    // Create a temporary framebuffer and empty cubemap
    final fbo = M3Framebuffer(size, size, useDepthTexture: false);
    final texCubemap = M3Texture.createEmptyCubemap(size);

    // Save previous state
    final prevFbo = gl.getParameter(WebGL.FRAMEBUFFER_BINDING) as Framebuffer?;
    final prevViewport = gl.getParameter(WebGL.VIEWPORT) as Int32List;

    // Temporary camera with 90 degree FOV
    final camCapture = M3Camera();
    camCapture.setViewport(0, 0, size, size, fovy: 90.0, near: 0.1, far: 1000.0);

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

    for (int i = 0; i < 6; i++) {
      // Bind face
      fbo.bindFace(faces[i], texCubemap.glTexture);

      // Clear
      gl.clearColor(0, 0, 0, 1);
      gl.clear(WebGL.COLOR_BUFFER_BIT | WebGL.DEPTH_BUFFER_BIT);

      // Setup camera
      camCapture.setLookat(position, position + targets[i], ups[i]);

      // Render skybox
      if (skybox != null) {
        skybox!.drawSkybox(camCapture);
      }

      // Render scene
      render(prog, camCapture, bSolid: bSolid);
    }

    // Restore state
    gl.bindFramebuffer(WebGL.FRAMEBUFFER, prevFbo);
    gl.viewport(prevViewport[0], prevViewport[1], prevViewport[2], prevViewport[3]);

    fbo.dispose();
    return texCubemap;
  }
}
