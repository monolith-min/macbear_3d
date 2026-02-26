// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'main_all.dart' hide Colors;

// ignore: camel_case_types
class SkyboxScene_02 extends M3Scene {
  GraphicsInfo? _gpuInfo;

  late M3ReflectionProbe _probe;

  @override
  Future<void> load() async {
    if (isLoaded) return;
    await super.load();

    _gpuInfo ??= PlatformInfo.getGraphicsInfo();
    PlatformInfo.checkGLExtensions();

    camera.setEuler(pi / 6, -pi / 6, 0, distance: 8);

    // 01: sample cubemap
    skybox = M3Skybox(M3Texture.createSampleCubemap());

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

    // 03: balls around
    final meshSphere = M3Mesh(M3Resources.unitSphere);
    meshSphere.mtr
      ..reflection = 0.0
      ..metallic = 0.0
      ..roughness = 1.0;
    final sphere = addMesh(meshSphere, Vector3(5, 2, 1));
    sphere
      ..rotation.setEuler(0, pi / 3, 0)
      ..color = Vector4(1.0, 0, 1.0, 1.0);

    // 04: reflection probe
    _probe = M3ReflectionProbe(position: ball.position);
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
          style: const TextStyle(color: Colors.white, fontSize: 9, fontFamily: 'monospace'),
        ),
      ),
    );
  }

  @override
  void update(double delta) {
    super.update(delta);
    // _probe.capture(this);
  }
}
