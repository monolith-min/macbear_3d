// ignore_for_file: file_names
import 'main_all.dart';

// ignore: camel_case_types
class CubeScene_01 extends M3Scene {
  @override
  Future<void> load() async {
    if (isLoaded) return;
    await super.load();

    camera.setEuler(pi / 6, -pi / 6, 0, distance: 8);

    // 01: box geometry
    addMesh(M3Mesh(M3BoxGeom(1.0, 1.0, 1.0)), Vector3.zero());

    final plane = addMesh(M3Mesh(M3PlaneGeom(20, 20, uvScale: Vector2.all(5.0))), Vector3(0, 0, -1));
    plane.color = Vector4(0.1, 1.0, 0.3, 1.0);
  }
}
