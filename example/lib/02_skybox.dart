// ignore_for_file: file_names
import 'package:flutter/material.dart' hide Matrix4;
import 'main_all.dart' hide Colors;

// ignore: camel_case_types
class SkyboxScene_02 extends M3Scene {
  GraphicsInfo? _gpuInfo;

  late M3ReflectionProbe _probe;
  late M3Entity _orbit1;
  late M3Entity _orbit2;
  double orbitAngle = 0.0;

  late M3Texture texYoshi;

  @override
  Future<void> load() async {
    if (isLoaded) return;
    await super.load();

    _gpuInfo ??= PlatformInfo.getGraphicsInfo();
    PlatformInfo.checkGLExtensions();

    camera.setEuler(pi / 6, -pi / 6, 0, distance: 8);

    // 01: sample cubemap
    // skybox = M3Skybox(M3Texture.createSampleCubemap());
    // 02: sample cubemap
    final strPrefix = 'example/nvlobby_';
    final strExt = 'jpg';
    skybox = await M3Skybox.createCubemap(
      '${strPrefix}xpos.$strExt',
      '${strPrefix}xneg.$strExt',
      '${strPrefix}ypos.$strExt',
      '${strPrefix}yneg.$strExt',
      '${strPrefix}zpos.$strExt',
      '${strPrefix}zneg.$strExt',
    );

    texYoshi = await M3Texture.loadTexture('example/nvlobby_zneg.jpg');

    M3Texture texGrid = M3Texture.createCheckerboard(size: 6);
    // 02: ball geometry
    final ballMesh = M3Mesh(M3Resources.unitSphere);
    ballMesh.mtr
      ..texDiffuse = texGrid
      ..reflection = 0.3
      ..metallic = 0.8
      ..roughness = 0.2;
    final ball = addMesh(ballMesh, Vector3.zero());
    ball.scale = Vector3.all(3);

    final plane = addMesh(M3Mesh(M3PlaneGeom(20, 20, uvScale: Vector2.all(10.0))), Vector3(0, 0, -5));
    M3Texture texGround = M3Texture.createCheckerboard(
      size: 2,
      lightColor: Vector4(0.65, 0.45, 0.25, 1),
      darkColor: Vector4(0.36, 0.22, 0.12, 1),
    );
    plane.mesh!.mtr.texDiffuse = texGround;

    final xAxisMesh = addMesh(M3Mesh(M3Resources.unitCube), Vector3(10, 0, -2));
    xAxisMesh.scale = Vector3(16, 0.5, 0.5);
    xAxisMesh.color = Vector4(1, 0, 0, 1);

    final yAxisMesh = addMesh(M3Mesh(M3Resources.unitCube), Vector3(0, 10, -2));
    yAxisMesh.scale = Vector3(0.5, 16, 0.5);
    yAxisMesh.color = Vector4(0, 1, 0, 1);

    final zAxisMesh = addMesh(M3Mesh(M3Resources.unitCube), Vector3(0, 0, 10));
    zAxisMesh.scale = Vector3(0.5, 0.5, 16);
    zAxisMesh.color = Vector4(0, 0, 1, 1);

    // 03: orbit around
    final meshSphere = M3Mesh(M3Resources.unitSphere);
    final meshTorus = M3Mesh(M3TorusGeom(0.6, 0.2));
    meshSphere.mtr
      ..reflection = 0.0
      ..metallic = 0.0
      ..roughness = 1.0;

    _orbit1 = addMesh(meshSphere, Vector3(5, 2, 1));
    _orbit1
      ..rotation.setEuler(0, pi / 3, 0)
      ..color = Vector4(1.0, 0, 1.0, 1.0);

    _orbit2 = addMesh(meshTorus, Vector3(0, 6, 0));
    _orbit2
      ..rotation.setEuler(0, pi / 7, 0)
      ..color = Vector4(0.0, 1.0, 0.3, 1.0);

    // 04: reflection probe
    _probe = M3ReflectionProbe(position: ball.position);

    ball.reflectionProbe = _probe;
  }

  @override
  Widget? buildUI(BuildContext context) {
    if (_gpuInfo == null) return null;
    return Positioned(
      top: 50,
      left: 8,
      child: Container(
        padding: const EdgeInsets.all(8),
        color: Colors.black54,
        child: Text(
          _gpuInfo.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace'),
        ),
      ),
    );
  }

  @override
  void render2D() {
    super.render2D();

    Matrix4 mat2D = Matrix4.identity();

    mat2D.setTranslation(Vector3(10.0, 200.0, 0.0));
    M3Shape2D.drawImage(texYoshi, mat2D, color: Vector4(0, 1, 1, 1));
  }

  @override
  void update(double delta) {
    super.update(delta);

    orbitAngle += delta * 0.5;
    _orbit1.position = Vector3(5 * cos(orbitAngle), 5 * sin(orbitAngle), 1);

    _orbit2.position = Vector3(3 * cos(orbitAngle * 0.7), 0, 4 * sin(orbitAngle * 0.7));

    _probe.capture(this);
  }
}
