// ignore_for_file: file_names
import 'main_all.dart';

// ignore: camel_case_types
class PbrTestScene_09 extends M3Scene {
  @override
  Future<void> load() async {
    if (isLoaded) return;
    await super.load();

    camera.setEuler(0, -pi / 4, 0, distance: 15);

    final sphereGeom = M3Resources.unitSphere;

    int rows = 5;
    int cols = 5;
    double spacing = 2.5;

    for (int i = 0; i < rows; i++) {
      double metallic = i / (rows - 1);
      for (int j = 0; j < cols; j++) {
        double roughness = j / (cols - 1);

        final mesh = M3Mesh(sphereGeom);
        mesh.mtr.diffuse = Vector4(1.0, 0.0, 0.0, 1.0); // Red base color
        mesh.mtr.metallic = metallic;
        mesh.mtr.roughness = max(roughness, 0.05); // Avoid zero roughness for GGX

        double x = (i - (rows - 1) / 2) * spacing;
        double y = (j - (cols - 1) / 2) * spacing;

        addMesh(mesh, Vector3(x, y, 0));
      }
    }

    // Add a ground plane
    final geomPlane = M3PlaneGeom(20, 20);
    final plane = addMesh(M3Mesh(geomPlane), Vector3(0, 0, -2));
    plane.mesh!.mtr.diffuse = Vector4(0.5, 0.5, 0.5, 1.0);
    plane.mesh!.mtr.metallic = 0.0;
    plane.mesh!.mtr.roughness = 0.8;

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
  }

  @override
  void update(double delta) {
    super.update(delta);

    // rotate light
    light.setEuler(light.euler.yaw + delta * 0.1, -pi / 5, 0, distance: light.distanceToTarget);

    // Rotate camera slowly
    // camera.setEuler(
    //   camera.euler.yaw + delta * 0.1,
    //   camera.euler.pitch,
    //   camera.euler.roll,
    //   distance: camera.distanceToTarget,
    // );
  }
}
