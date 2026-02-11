// ignore_for_file: file_names
import 'main_all.dart';

// ignore: camel_case_types
class SkyboxScene_02 extends M3Scene {
  @override
  Future<void> load() async {
    if (isLoaded) return;
    await super.load();

    camera.setEuler(pi / 6, -pi / 6, 0, distance: 8);

    // 01: sample cubemap
    skybox = M3Skybox(M3Texture.createSampleCubemap());

    M3Texture texGrid = M3Texture.createCheckerboard(size: 6);
    // 02: ball geometry
    final ballMesh = M3Mesh(M3Resources.unitSphere);
    ballMesh.mtr.texDiffuse = texGrid;
    ballMesh.mtr.reflection = 0.3;
    ballMesh.mtr.metallic = 0.8;
    ballMesh.mtr.roughness = 0.2;
    final ball = addMesh(ballMesh, Vector3.zero());
    ball.scale = Vector3.all(3);

    // 03: cube geometry
    final meshCube = M3Mesh(M3Resources.unitCube);
    meshCube.mtr.reflection = 0.0;
    meshCube.mtr.metallic = 0.0;
    meshCube.mtr.roughness = 1.0;
    final cube = addMesh(meshCube, Vector3(5, 6, 3));
    cube
      ..scale = Vector3(2, 3, 4)
      ..rotation.setEuler(0, pi / 3, 0)
      ..color = Vector4(1.0, 0, 1.0, 1.0);
  }
}
