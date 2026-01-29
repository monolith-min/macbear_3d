import 'package:vector_math/vector_math.dart';

import '../engine/resources.dart';
import '../gltf/gltf_parser.dart';
import 'texture.dart';

/// Material properties for rendering (diffuse color, specular, shininess, textures).
class M3Material {
  Vector4 diffuse = Vector4(1.0, 1.0, 1.0, 1.0);
  Vector3 specular = Vector3(0.3, 0.3, 0.3);
  double shininess = 16; // glossiness [0 ~ 128]
  double reflection = 0.0;

  // textures
  M3Texture texDiffuse = M3Resources.texWhite;
  Matrix3 texMatrix = Matrix3.identity();

  M3Material();

  /// Creates a deep copy of this material.
  /// Vector and Matrix properties are cloned, while texture references are shared.
  M3Material clone() {
    return M3Material()..copyFrom(this);
  }

  /// Copies all properties from another material.
  void copyFrom(M3Material other) {
    diffuse.setFrom(other.diffuse);
    specular.setFrom(other.specular);
    shininess = other.shininess;
    reflection = other.reflection;
    texDiffuse = other.texDiffuse;
    texMatrix.setFrom(other.texMatrix);
  }

  factory M3Material.fromGltf(GltfMaterial gltfMat, GltfDocument doc) {
    final mtr = M3Material();
    // Base Color
    mtr.diffuse = gltfMat.baseColorFactor;

    // Base Color Texture
    if (gltfMat.baseColorTextureIndex != null) {
      final texIndex = gltfMat.baseColorTextureIndex!;
      if (texIndex < doc.runtimeTextures.length) {
        final tex = doc.runtimeTextures[texIndex];
        if (tex is M3Texture) {
          mtr.texDiffuse = tex;
        }
      }
    }
    return mtr;
  }
}
