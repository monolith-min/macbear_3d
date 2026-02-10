// ignore_for_file: file_names
import 'package:flutter/material.dart' as fm;
import 'main_all.dart';

// ignore: camel_case_types
class ObjTeapotScene_04 extends M3Scene {
  M3Entity? _teapot;
  M3Material? mtrTeapot;

  @override
  Future<void> load() async {
    if (isLoaded) return;
    await super.load();

    camera.setEuler(pi / 6, -pi / 6, 0, distance: 8);

    // plane geometry
    final geomPlane = M3PlaneGeom(
      10,
      10,
      widthSegments: 60,
      heightSegments: 60,
      uvScale: Vector2.all(5.0),
      onVertex: (x, y) {
        double rad = pi / 2;
        return (cos(x * rad) + sin(y * rad)) / 2;
      },
    );
    final plane = addMesh(M3Mesh(geomPlane), Vector3(0, 0, -1));

    M3Texture texGround = M3Texture.createCheckerboard(
      size: 2,
      lightColor: Vector4(.7, 1, .5, 1),
      darkColor: Vector4(.5, 0.8, .3, 1),
    );
    plane.mesh!.mtr.texDiffuse = texGround;

    // 04: obj model - using M3Mesh.load()
    final meshTeapot = await M3Mesh.load('example/teapot.obj');
    mtrTeapot = meshTeapot.mtr;
    mtrTeapot!.reflection = 0.5;
    mtrTeapot!.metallic = 1.0;
    mtrTeapot!.roughness = 0.2;

    _teapot = addMesh(meshTeapot, Vector3(0, 0, 0));
    _teapot!.color = Vector4(1.0, 0.5, 0.0, 1);

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

    double sec = totalTime;
    light.setEuler(sec * pi / 18, -pi / 3, 0, distance: light.distanceToTarget); // rotate light
    // debugPrint('Light Direction: $dirLight');

    double angle = sec * pi / 4; // 45 degree per second

    if (_teapot != null) {
      final quatYPos90 = Quaternion.euler(0, pi / 2, 0);
      _teapot!.rotation = quatYPos90 * Quaternion.euler(angle, 0, 0);
    }
  }

  @override
  fm.Widget buildUI(fm.BuildContext context) {
    if (mtrTeapot == null) return const fm.SizedBox.shrink();

    return fm.Positioned(
      top: 10,
      left: 10,
      child: fm.Container(
        padding: const fm.EdgeInsets.all(12),
        decoration: fm.BoxDecoration(color: fm.Colors.black54, borderRadius: fm.BorderRadius.circular(12)),
        child: fm.Column(
          mainAxisSize: fm.MainAxisSize.min,
          crossAxisAlignment: fm.CrossAxisAlignment.start,
          children: [
            const fm.Text(
              "Teapot Material",
              style: fm.TextStyle(color: fm.Colors.white, fontWeight: fm.FontWeight.bold),
            ),
            const fm.SizedBox(height: 8),
            _buildSlider("Metallic", () => mtrTeapot!.metallic, (val) {
              mtrTeapot!.metallic = val;
            }),
            _buildSlider("Roughness", () => mtrTeapot!.roughness, (val) {
              mtrTeapot!.roughness = val;
              mtrTeapot!.reflection = 1.0 - val;
            }),
          ],
        ),
      ),
    );
  }

  fm.Widget _buildSlider(String label, double Function() getValue, fm.ValueChanged<double> onChanged) {
    return fm.StatefulBuilder(
      builder: (context, setState) {
        final double value = getValue();
        return fm.Row(
          mainAxisSize: fm.MainAxisSize.min,
          children: [
            fm.SizedBox(
              width: 80,
              child: fm.Text(label, style: const fm.TextStyle(color: fm.Colors.white70, fontSize: 12)),
            ),
            fm.SizedBox(
              width: 150,
              child: fm.Slider(
                value: value,
                min: 0,
                max: 1,
                activeColor: fm.Colors.lightGreen,
                onChanged: (val) {
                  setState(() {
                    onChanged(val);
                  });
                },
              ),
            ),
            fm.Text(value.toStringAsFixed(2), style: const fm.TextStyle(color: fm.Colors.white, fontSize: 12)),
          ],
        );
      },
    );
  }
}
