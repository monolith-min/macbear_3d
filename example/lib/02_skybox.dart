// ignore_for_file: file_names
import 'main_all.dart';

// ignore: camel_case_types
class SkyboxScene_02 extends M3Scene {
  @override
  Future<void> load() async {
    if (isLoaded) return;
    await super.load();

    camera.setEuler(pi / 6, -pi / 6, 0, distance: 8);

    // 01: ball geometry
    final ball = addMesh(M3Mesh(M3Resources.unitSphere), Vector3.zero());
    M3Texture texGrid = M3Texture.createCheckerboard(size: 6);
    ball.scale = Vector3.all(3);
    ball.mesh!.mtr.texDiffuse = texGrid;
    ball.mesh!.mtr.reflection = 0.3;

    // 02: sample cubemap
    skybox = M3Skybox(M3Texture.createSampleCubemap());
  }
}
