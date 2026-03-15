import 'package:vector_math/vector_math.dart';

/// A hierarchical transform node with position, rotation, scale, and parent/child relationships.
///
/// Lazily recomputes the world matrix when marked dirty.
class M3Transform {
  Vector3 _position = Vector3.zero();
  Quaternion _rotation = Quaternion.identity();
  Vector3 _scale = Vector3.all(1);

  Vector3 get position => _position;
  set position(Vector3 v) {
    _position = v;
    markDirty();
  }

  Quaternion get rotation => _rotation;
  set rotation(Quaternion q) {
    _rotation = q;
    markDirty();
  }

  Vector3 get scale => _scale;
  set scale(Vector3 v) {
    _scale = v;
    markDirty();
  }

  M3Transform? _parent;
  M3Transform? get parent => _parent;
  set parent(M3Transform? p) {
    if (_parent == p) return;
    _parent?.children.remove(this);
    _parent = p;
    _parent?.children.add(this);
    markDirty();
  }

  final List<M3Transform> children = [];

  bool _dirty = true;
  bool get isDirty => _dirty;

  Matrix4 _worldMatrix = Matrix4.identity();

  void markDirty() {
    _dirty = true;
    for (final c in children) {
      c.markDirty();
    }
  }

  Matrix4 get worldMatrix {
    if (_dirty) {
      _rebuild();
    }
    return _worldMatrix;
  }

  void _rebuild() {
    final local = Matrix4.compose(_position, _rotation, _scale);
    _worldMatrix = parent != null ? parent!.worldMatrix * local : local;
    _dirty = false;
  }
}
