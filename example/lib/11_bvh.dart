// ignore_for_file: file_names
import 'package:flutter/services.dart' show rootBundle;
import 'main_all.dart';

// ignore: camel_case_types
class BvhScene_11 extends M3Scene {
  BvhSkeleton? skeleton;

  @override
  Future<void> load() async {
    if (isLoaded) return;
    await super.load();

    camera.setEuler(pi / 6, -pi / 6, 0, distance: 20);

    // BVH resource: Biovision hierarchical data
    // https://theorangeduck.com/media/uploads/BVHView/bvhview.html
    // http://lo-th.github.io/olympe/BVH_player.html
    // http://mocapdata.com/
    // Load and parse BVH from assets
    final filaname = 'assets/example/bvh/01_02.bvh';
    final filaname2 = 'assets/example/bvh/example.bvh';
    final filaname3 = 'assets/example/bvh/baseball-05-lead-yokoyama.bvh';
    final bvhString = await rootBundle.loadString(filaname3);
    final bvhData = BvhParser.parse(bvhString);
    skeleton = BvhSkeleton(bvhData);
    skeleton?.rootTransform.scale = Vector3.all(0.025);
    skeleton?.rootTransform.position = Vector3.zero();
    skeleton?.rootTransform.rotation = Quaternion.fromRotation(M3Constants.rotXPos90);
    skeleton?.addToScene(this);

    final plane = addMesh(M3Mesh(M3PlaneGeom(50, 50, uvScale: Vector2.all(5.0))), Vector3(0, 0, -5));
    plane.color = Vector4(0.1, 1.0, 0.3, 1.0);
  }

  @override
  void update(double delta) {
    super.update(delta);
    skeleton?.update(delta);
  }
}
