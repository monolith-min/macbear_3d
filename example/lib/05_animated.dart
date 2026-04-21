// ignore_for_file: file_names
import 'package:flutter/material.dart' as fm;

import 'main_all.dart';

// ignore: camel_case_types
class AnimatedScene_05 extends M3Scene {
  // Gltf models
  final List<M3Entity> _lionParts = [];
  M3Entity? _man;
  M3Entity? _fox;
  int _foxAnimIndex = 0;
  double _foxAnimTimer = 0.0;

  // Rogue model (loadAll - per-part toggle)
  final List<M3Entity> _rogueParts = [];

  // Rogue on car
  final List<M3Entity> _carParts = [];
  final List<M3Entity> _rogueOnCarParts = [];

  // Sitting pose transition
  List<dynamic>? _rogueCarNodes;
  M3Animator? _rogueCarAnimator;
  bool _wantSit = false;
  double _sitT = 0.0; // 0=standing, 1=sitting
  static const double _sitDuration = 1.0;
  // bone index → [standing rotation, sitting rotation]
  final Map<int, List<Quaternion>> _sitBoneData = {};
  // Bone indices from debug output:
  // 22=upperleg.l, 26=upperleg.r, 21=lowerleg.l, 25=lowerleg.r
  // 18=spine, 27=hips
  // [angle, axisX, axisY, axisZ] - axisAngle rotation in bone local space
  static const _sitBoneConfig = <int, List<double>>{
    22: [-1.2, 1, 0, 0], // upperleg.l: bend forward ~70°
    26: [-1.2, 1, 0, 0], // upperleg.r: bend forward ~70°
    21: [1.4, 1, 0, 0], // lowerleg.l: bend knee ~80°
    25: [1.4, 1, 0, 0], // lowerleg.r: bend knee ~80°
    18: [0.15, 1, 0, 0], // spine: lean back slightly
  };

  // BVH skeleton
  BvhSkeleton? skeleton;

  @override
  Future<void> load() async {
    if (isLoaded) return;
    await super.load();

    camera.setLookat(Vector3(10, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, 1));
    camera.setEuler(pi / 6, -pi / 6, 0, distance: 12);

    M3Texture texGround = M3Texture.createCheckerboard(
      size: 10,
      lightColor: Vector4(.7, 1, .5, 1),
      darkColor: Vector4(.5, 0.8, .3, 1),
    );
    // plane geometry

    final plane = addMesh(M3Mesh(M3PlaneGeom(20, 20, uvScale: Vector2.all(8.0))), Vector3(0, 0, 0));
    plane.mesh!.mtr.texDiffuse = texGround;

    // 05-1: GLTF model - using M3Mesh.load()
    final meshGltf = await M3Mesh.load('example/CesiumMan.glb');
    meshGltf.animator?.play(0);
    _man = addMesh(meshGltf, Vector3(0, 0, 0));
    _man!.color = Colors.white;
    _man!.rotation = Quaternion.euler(0, pi / 2, 0);
    _man!.scale = Vector3.all(3);

    // 05-2: GLTF model - using M3Mesh.loadAll() for multi-mesh models
    final lionMeshes = await M3Mesh.loadAll('example/pug_3d_model.glb');
    for (final meshPart in lionMeshes) {
      final entity = addMesh(meshPart, Vector3(0, 5, 2));
      entity.scale = Vector3.all(1.525);
      _lionParts.add(entity);
    }

    final meshFox = await M3Mesh.load('example/Fox.glb');
    meshFox.animator?.play(0);
    _fox = addMesh(meshFox, Vector3(-2, 0, 0));
    _fox!.rotation = Quaternion.euler(0, pi / 2, 0);
    _fox!.scale = Vector3.all(0.04);

    // Fox 1: Survey Animation (Index 0)
    final mesh1 = meshFox.clone();
    mesh1.animator?.play(0);
    mesh1.animator?.playRate = 0.6;
    final entity1 = addMesh(mesh1, Vector3(-4, 0, 0));
    entity1.rotation = Quaternion.euler(0, pi / 2, 0);
    entity1.scale = Vector3.all(0.05);
    entity1.color = Vector4(1, 0.5, 0.5, 1); // Reddish

    // Fox 2: Walk Animation (Index 1)
    final mesh2 = meshFox.clone();
    mesh2.animator?.play(1);
    final entity2 = addMesh(mesh2, Vector3(2, 0, 0));
    entity2.rotation = Quaternion.euler(0, pi / 2, 0);
    entity2.scale = Vector3.all(0.03);
    entity2.color = Vector4(0.5, 1, 0.5, 1); // Greenish

    // Fox 3: Run Animation (Index 2)
    final mesh3 = meshFox.clone();
    mesh3.animator?.play(2);
    final entity3 = addMesh(mesh3, Vector3(4, 0, 0));
    entity3.rotation = Quaternion.euler(0, pi / 2, 0);
    entity3.scale = Vector3.all(0.02);
    entity3.color = Vector4(0.5, 0.5, 1, 1); // Blueish

    // set background color
    M3AppEngine.backgroundColor = Vector3(0.3, 0.1, 0.3);

    // BVH resource: Biovision hierarchical data
    // https://theorangeduck.com/media/uploads/BVHView/bvhview.html
    // http://lo-th.github.io/olympe/BVH_player.html
    // BVH data from mocapdata.com:
    // This motion capture data is licensed by mocapdata.com, Eyes, JAPAN Co. Ltd. under the Creative Commons Attribution 2.1 Japan License.
    // To view a copy of this license, contact mocapdata.com, Eyes, JAPAN Co. Ltd. or visit http://creativecommons.org/licenses/by/2.1/jp/ .
    // http://mocapdata.com/
    // (C) Copyright Eyes, JAPAN Co. Ltd. 2008-2009.
    // Load and parse BVH from assets
    final bvhFile = 'assets/example/karate-03-spin kick-yokoyama.bvh';
    skeleton = await BvhSkeleton.load(bvhFile);
    skeleton?.rootTransform.scale = Vector3.all(0.025);
    skeleton?.rootTransform.position = Vector3(0, 4, 0);
    skeleton?.rootTransform.rotation = Quaternion.fromRotation(M3Constants.rotXPos90);
    skeleton?.addToScene(this);

    // 05-rogue (loadAll): per-part toggle
    final rogueMeshes = await M3Mesh.loadAll('example/rogue.glb');
    if (rogueMeshes.isNotEmpty) {
      rogueMeshes[0].animator?.play(1);

      for (int i = 0; i < rogueMeshes.length; i++) {
        final entity = addMesh(rogueMeshes[i], Vector3(0, -4, 0));
        entity.scale = Vector3.all(2.0);
        entity.rotation = Quaternion.fromRotation(M3Constants.rotXPos90);
        _rogueParts.add(entity);
      }
    }

    // 05-car: fcar with rogue sitting on top
    final carMeshes = await M3Mesh.loadAll('example/fcar.glb');
    final carPos = Vector3(6, 6, 0);
    for (final meshPart in carMeshes) {
      final entity = addMesh(meshPart, carPos);
      entity.scale = Vector3.all(2.0);
      entity.rotation = Quaternion.fromRotation(M3Constants.rotXPos90);
      _carParts.add(entity);
    }

    // Rogue on car - with sit/stand toggle
    final rogueCarMeshes = await M3Mesh.loadAll('example/rogue.glb');
    if (rogueCarMeshes.isNotEmpty) {
      _rogueCarNodes = rogueCarMeshes[0].nodes;
      _rogueCarAnimator = rogueCarMeshes[0].animator;
      _rogueCarAnimator?.isPlaying = false;

      // Save standing rotations and compute sitting targets
      if (_rogueCarNodes != null) {
        for (final entry in _sitBoneConfig.entries) {
          final boneIdx = entry.key;
          final euler = entry.value;
          if (boneIdx < _rogueCarNodes!.length) {
            final standRot = Quaternion.copy(_rogueCarNodes![boneIdx].rotation);
            final axis = Vector3(euler[1], euler[2], euler[3]);
            final deltaRot = Quaternion.axisAngle(axis, euler[0]);
            final sitRot = standRot * deltaRot; // local space rotation
            _sitBoneData[boneIdx] = [standRot, sitRot];
          }
        }
      }

      for (int i = 0; i < rogueCarMeshes.length; i++) {
        final entity = addMesh(rogueCarMeshes[i], carPos + Vector3(0, 0, 5.5));
        entity.scale = Vector3.all(2.0);
        entity.rotation = Quaternion.fromRotation(M3Constants.rotXPos90);
        _rogueOnCarParts.add(entity);
      }
    }
  }

  @override
  void update(double delta) {
    super.update(delta);

    double sec = totalTime;

    light.setEuler(sec * pi / 18, -pi / 3, 0, distance: light.distanceToTarget); // rotate light

    // Update Fox Animation Cycle
    if (_fox != null) {
      _foxAnimTimer += delta;
      if (_foxAnimTimer > 3.0) {
        _foxAnimTimer = 0.0;
        _foxAnimIndex = (_foxAnimIndex + 1) % 3;
        _fox!.mesh?.animator?.crossFade(_foxAnimIndex, 0.5);
        debugPrint('Fox animation cross-fade to index: $_foxAnimIndex');
      }
    }

    double angle = sec * pi / 10; // 18 degree per second

    for (final part in _lionParts) {
      final quatYPos90 = Quaternion.euler(0, pi / 2, 0);
      part.rotation = quatYPos90 * Quaternion.euler(angle, 0, 0);
    }

    skeleton?.update(delta);

    // Sitting pose transition
    if (_rogueCarNodes != null && _sitBoneData.isNotEmpty) {
      final prevT = _sitT;
      if (_wantSit && _sitT < 1.0) {
        _sitT = (_sitT + delta / _sitDuration).clamp(0.0, 1.0);
      } else if (!_wantSit && _sitT > 0.0) {
        _sitT = (_sitT - delta / _sitDuration).clamp(0.0, 1.0);
      }
      if (_sitT != prevT) {
        // Smooth ease-in-out
        final t = _sitT * _sitT * (3 - 2 * _sitT);
        for (final entry in _sitBoneData.entries) {
          final node = _rogueCarNodes![entry.key];
          final stand = entry.value[0];
          final sit = entry.value[1];
          // Slerp between standing and sitting
          node.rotation = _slerpQ(stand, sit, t);
        }
        _rogueCarAnimator?.refreshHierarchy();
      }
    }

    // Sync non-skinned meshes (weapons) to their animated node transforms
    for (final list in [_rogueParts, _rogueOnCarParts]) {
      for (final entity in list) {
        final mesh = entity.mesh;
        if (mesh == null || mesh.skin != null) continue;
        if (mesh.sourceNodeIndex == null || mesh.nodes == null) continue;
        mesh.initMatrix.setFrom(mesh.nodes![mesh.sourceNodeIndex!].worldMatrix);
      }
    }
  }

  static Quaternion _slerpQ(Quaternion a, Quaternion b, double t) {
    double dot = a.x * b.x + a.y * b.y + a.z * b.z + a.w * b.w;
    final Quaternion b2;
    if (dot < 0) {
      dot = -dot;
      b2 = Quaternion(-b.x, -b.y, -b.z, -b.w);
    } else {
      b2 = b;
    }
    if (dot > 0.9995) {
      return Quaternion(a.x + (b2.x - a.x) * t, a.y + (b2.y - a.y) * t, a.z + (b2.z - a.z) * t, a.w + (b2.w - a.w) * t)
        ..normalize();
    }
    final theta = acos(dot);
    final sinTheta = sin(theta);
    final wa = sin((1 - t) * theta) / sinTheta;
    final wb = sin(t * theta) / sinTheta;
    return Quaternion(a.x * wa + b2.x * wb, a.y * wa + b2.y * wb, a.z * wa + b2.z * wb, a.w * wa + b2.w * wb);
  }

  @override
  fm.Widget buildUI(fm.BuildContext context) {
    if (_rogueParts.isEmpty) return const fm.SizedBox.shrink();

    return fm.Positioned(
      top: 10,
      left: 10,
      child: fm.Container(
        padding: const fm.EdgeInsets.all(12),
        decoration: fm.BoxDecoration(color: fm.Colors.black54, borderRadius: fm.BorderRadius.circular(12)),
        child: fm.StatefulBuilder(
          builder: (context, setState) {
            return fm.Column(
              mainAxisSize: fm.MainAxisSize.min,
              crossAxisAlignment: fm.CrossAxisAlignment.start,
              children: [
                const fm.Text(
                  'Rogue Parts',
                  style: fm.TextStyle(color: fm.Colors.white, fontWeight: fm.FontWeight.bold, fontSize: 13),
                ),
                const fm.SizedBox(height: 4),
                for (int i = 0; i < _rogueParts.length; i++)
                  fm.Row(
                    mainAxisSize: fm.MainAxisSize.min,
                    children: [
                      fm.SizedBox(
                        width: 24,
                        height: 24,
                        child: fm.Checkbox(
                          value: _rogueParts[i].visible,
                          activeColor: fm.Colors.lightGreen,
                          onChanged: (val) {
                            setState(() => _rogueParts[i].visible = val ?? true);
                          },
                        ),
                      ),
                      const fm.SizedBox(width: 8),
                      fm.Text('Part $i', style: const fm.TextStyle(color: fm.Colors.white70, fontSize: 11)),
                    ],
                  ),
                const fm.SizedBox(height: 12),
                const fm.Text(
                  'Rogue on Car',
                  style: fm.TextStyle(color: fm.Colors.white, fontWeight: fm.FontWeight.bold, fontSize: 13),
                ),
                const fm.SizedBox(height: 4),
                fm.ElevatedButton.icon(
                  style: fm.ElevatedButton.styleFrom(
                    backgroundColor: _wantSit ? fm.Colors.lightGreen : fm.Colors.grey[700],
                  ),
                  onPressed: () => setState(() => _wantSit = !_wantSit),
                  icon: fm.Icon(_wantSit ? fm.Icons.event_seat : fm.Icons.person, size: 16),
                  label: fm.Text(_wantSit ? 'Stand Up' : 'Sit Down', style: const fm.TextStyle(fontSize: 12)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
