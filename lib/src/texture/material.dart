import 'package:vector_math/vector_math.dart';

import '../engine/resources.dart';
import '../gltf/gltf_parser.dart';
import 'texture.dart';

/// Alpha blending modes for materials.
enum M3AlphaMode {
  /// Standard opaque rendering.
  opaque,

  /// Semi-transparent rendering with alpha blending.
  blend,

  /// Binary transparency (pixel is either visible or discarded).
  mask,
}

/// Material properties for rendering (diffuse color, specular, shininess, textures).
class M3Material {
  Vector4 diffuse = Vector4(1.0, 1.0, 1.0, 1.0);
  Vector3 specular = Vector3(0.3, 0.3, 0.3);
  double shininess = 16; // glossiness [0 ~ 128]
  double reflection = 0.0;
  double metallic = 0.0;
  double roughness = 0.8;
  Vector3 emissive = Vector3.zero(); // self-illumination color (0=none, 1=full)
  M3AlphaMode alphaMode = M3AlphaMode.opaque;
  int renderOrder = 0; // manual override for fine-tuned sorting

  // textures
  M3Texture texDiffuse = M3Resources.texWhite;
  M3Texture? texEmissive; // emissive texture (null = use emissive color only)
  Matrix3 texMatrix = Matrix3.identity();

  M3Material();

  /// Sets the material to a matte (diffuse-only) state.
  /// No reflection, no specular highlights, and full roughness.
  void setMatte() {
    metallic = 0.0;
    roughness = 1.0;
    reflection = 0.0;
    specular.setZero();
    shininess = 0.0;
  }

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
    metallic = other.metallic;
    roughness = other.roughness;
    emissive.setFrom(other.emissive);
    alphaMode = other.alphaMode;
    renderOrder = other.renderOrder;
    texDiffuse = other.texDiffuse;
    texEmissive = other.texEmissive;
    texMatrix.setFrom(other.texMatrix);
  }

  factory M3Material.fromGltf(GltfMaterial gltfMat, GltfDocument doc) {
    final mtr = M3Material();
    // Base Color
    mtr.diffuse = gltfMat.baseColorFactor;
    mtr.metallic = gltfMat.metallicFactor;
    mtr.roughness = gltfMat.roughnessFactor;
    if (gltfMat.alphaMode == 'BLEND') {
      mtr.alphaMode = M3AlphaMode.blend;
    } else if (gltfMat.alphaMode == 'MASK') {
      mtr.alphaMode = M3AlphaMode.mask;
    }

    mtr.emissive.setFrom(gltfMat.emissiveFactor);

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

    // Emissive Texture
    if (gltfMat.emissiveTextureIndex != null) {
      final texIndex = gltfMat.emissiveTextureIndex!;
      if (texIndex < doc.runtimeTextures.length) {
        final tex = doc.runtimeTextures[texIndex];
        if (tex is M3Texture) {
          mtr.texEmissive = tex;
          // If emissiveFactor is zero but texture exists, default to white
          if (mtr.emissive.length2 < 0.001) {
            mtr.emissive = Vector3(1.0, 1.0, 1.0);
          }
        }
      }
    }
    return mtr;
  }
}
