import 'dart:convert';

// Macbear3D engine
import '../m3_internal.dart';
import '../gltf/gltf_loader.dart';
import '../gltf/gltf_parser.dart';
import 'animator.dart';
import 'obj_loader.dart';

/// Skeletal animation skin data containing bone matrices and inverse bind matrices.
///
/// Bone matrices represent the current pose of the character, while
/// inverse bind matrices transform vertices from model space to bone space.
class M3Skin {
  /// The current transformation matrices for each joint/bone.
  final List<Matrix4> boneMatrices;

  /// The inverse bind matrices for each joint, used in vertex skinning.
  final List<Matrix4>? inverseBindMatrices;

  /// The nodes associated with each joint (for tracking hierarchical transforms).
  final List<GltfNode>? jointNodes;

  /// Creates a skin for a specified number of bones.
  M3Skin(int boneCount, {this.inverseBindMatrices, this.jointNodes})
    : boneMatrices = List.generate(boneCount, (_) => Matrix4.identity());

  /// Returns the total number of bones in this skin.
  int get boneCount => boneMatrices.length;

  /// Updates the bone matrices based on the current transforms of the joint nodes.
  ///
  /// The [meshWorldMatrix] is the world-space transform of the mesh node itself.
  /// We need its inverse to transform the calculated joint world matrices back into
  /// the mesh's local space. This is essential because the vertex shader will
  /// apply the model's world transform (via the MVP matrix).
  ///
  /// Transformation flow for a vertex:
  /// Vertex (Mesh Local) -> [IBM] -> Joint Bind Space -> [Joint World] -> World Space -> [Mesh World Inv] -> Mesh Local (deformed)
  void update(Matrix4? meshWorldMatrix) {
    if (jointNodes == null) return;

    // By default, we assume the mesh matches the entity's local origin (Identity).
    // The inverse is used to "cancel out" the world matrix that the shader will re-apply.
    final meshWorldInv = meshWorldMatrix != null ? Matrix4.inverted(meshWorldMatrix) : Matrix4.identity();

    for (int i = 0; i < boneCount; i++) {
      final jointNode = jointNodes![i];
      final ibm = inverseBindMatrices != null ? inverseBindMatrices![i] : Matrix4.identity();

      // BoneMatrix = MeshWorldInverse * JointWorldMatrix * InverseBindMatrix
      // This transforms vertices from MeshLocal -> JointLocal(Bind) -> JointWorld -> MeshLocal
      boneMatrices[i].setFrom(meshWorldInv * jointNode.worldMatrix * ibm);
    }

    if (_debugCount < 1) {
      debugPrint('M3Skin: first bone matrix storage: ${boneMatrices[0].storage}');
      _debugCount++;
    }
  }

  /// Creates a copy of this skin pointing to a new set of joint nodes.
  M3Skin clone(List<GltfNode> newNodes) {
    return M3Skin(
      boneCount,
      inverseBindMatrices: inverseBindMatrices?.map((m) => m.clone()).toList(),
      jointNodes: newNodes,
    );
  }

  int _debugCount = 0;
}

/// A 3D mesh object that combines geometry, material properties, and optional skin for animation.
///
/// This class acts as the primary container for a renderable 3D object and supports
/// loading from various file formats (.obj, .gltf, .glb).
class M3Mesh {
  /// The material properties (textures, colors, etc.) for this mesh.
  M3Material mtr;

  /// The geometric data (vertices, indices, etc.) for this mesh.
  M3Geom geom;

  /// Optional initial transform from glTF mesh node.
  Matrix4 initMatrix = Matrix4.identity();

  /// Optional skin data for skeletal animation.
  M3Skin? skin;

  /// Optional animator for playing back animations.
  M3Animator? animator;

  /// The skeletal hierarchy nodes for this mesh instance.
  List<GltfNode>? nodes;

  /// Index of the source glTF node that owns this mesh (set by loadAll).
  int? sourceNodeIndex;

  /// Creates a mesh from the given geometry and optional material/skin.
  M3Mesh(this.geom, {M3Material? material, this.skin}) : mtr = material ?? M3Material();

  /// Loads a model from a file path or URL.
  ///
  /// Automatically detects the file format by extension (.obj, .gltf, .glb)
  /// and the source (asset or remote URL).
  /// For multi-mesh models, only the first mesh is returned. Use [loadAll] instead.
  static Future<M3Mesh> load(String path) async {
    final meshes = await loadAll(path);
    return meshes.first;
  }

  /// Loads all meshes from a model file.
  ///
  /// For glTF/GLB files with multiple meshes (e.g. a character split into
  /// head, body, legs), each mesh is returned as a separate [M3Mesh] so they
  /// can be individually added to the scene. All meshes share the same
  /// animator and node hierarchy when applicable.
  static Future<List<M3Mesh>> loadAll(String path) async {
    final buffer = await M3ResourceManager.loadBuffer(path);
    final ext = path.split('.').last.toLowerCase().split('?').first;

    if (ext == 'obj') {
      final bytes = buffer.asUint8List();
      final geom = M3ObjLoader.parse(utf8.decode(bytes), path);
      return [M3Mesh(geom)];
    } else if (ext == 'gltf' || ext == 'glb') {
      final doc = await M3GltfLoader.loadFromBytes(buffer.asUint8List(), path);
      return _meshListFromGltfDoc(doc);
    } else {
      throw UnsupportedError('Unsupported format: $ext');
    }
  }

  /// Builds one [M3Mesh] per glTF node that references a mesh.
  ///
  /// Each node–mesh pair becomes its own [M3Mesh] with the node's world
  /// transform baked into [initMatrix]. Animator and skin are attached to
  /// the first mesh that qualifies.
  static List<M3Mesh> _meshListFromGltfDoc(dynamic doc) {
    // Compute world matrices for the whole node tree
    for (final rootIdx in (doc.rootNodes as List<int>)) {
      (doc.nodes[rootIdx] as GltfNode).computeWorldMatrix(Matrix4.identity(), (doc.nodes as List).cast<GltfNode>());
    }

    // Shared animator (created once, attached to first mesh)
    M3Animator? sharedAnimator;
    if (doc.animations.isNotEmpty) {
      final nodeMap = {for (int i = 0; i < doc.nodes.length; i++) i: doc.nodes[i]};
      sharedAnimator = M3Animator((doc.animations as List).cast<GltfAnimation>(), nodeMap.cast<int, GltfNode>());
    }

    final List<M3Mesh> results = [];

    for (int nodeIdx = 0; nodeIdx < doc.nodes.length; nodeIdx++) {
      final node = doc.nodes[nodeIdx];
      if (node.meshIndex == null) continue;
      final meshIdx = node.meshIndex as int;
      if (meshIdx >= doc.meshes.length) continue;

      final gltfMesh = doc.meshes[meshIdx] as GltfMesh;

      for (final primitive in gltfMesh.primitives) {
        final positions = primitive.getPositions();
        if (positions == null || positions.isEmpty) continue;

        final geom = M3GltfGeom.fromPrimitive(primitive);

        // Material
        M3Material? mtr;
        if (primitive.materialIndex != null && primitive.materialIndex! < doc.materials.length) {
          mtr = M3Material.fromGltf(doc.materials[primitive.materialIndex!], doc);
        }

        // Skin
        M3Skin? skin;
        final int? skinIdx = (node as GltfNode).skinIndex ?? primitive.skinIndex;
        if (skinIdx != null && skinIdx < doc.skins.length) {
          final gltfSkin = doc.skins[skinIdx];
          final ibm = gltfSkin.getInverseBindMatrices();
          final List<Matrix4>? inverseMatrices = ibm != null
              ? List.generate(gltfSkin.joints.length, (i) {
                  return Matrix4.fromFloat32List(ibm.sublist(i * 16, i * 16 + 16));
                })
              : null;
          skin = M3Skin(
            gltfSkin.joints.length,
            inverseBindMatrices: inverseMatrices,
            jointNodes: (gltfSkin.joints as List<int>).map<GltfNode>((index) => doc.nodes[index] as GltfNode).toList(),
          );
        }

        final mesh = M3Mesh(geom, material: mtr, skin: skin);
        mesh.initMatrix.setFrom(node.worldMatrix);
        mesh.nodes = doc.nodes;
        mesh.sourceNodeIndex = nodeIdx;

        // Attach animator to the first mesh only
        if (sharedAnimator != null && results.isEmpty) {
          mesh.animator = sharedAnimator;
        }

        results.add(mesh);
      }
    }

    // Fallback: if no node references a mesh, load meshes[0].primitives[0]
    if (results.isEmpty && doc.meshes.isNotEmpty) {
      final primitive = (doc.meshes[0] as GltfMesh).primitives[0];
      final geom = M3GltfGeom.fromPrimitive(primitive);
      M3Material? mtr;
      if (primitive.materialIndex != null && primitive.materialIndex! < doc.materials.length) {
        mtr = M3Material.fromGltf(doc.materials[primitive.materialIndex!], doc);
      }
      final mesh = M3Mesh(geom, material: mtr);
      mesh.nodes = doc.nodes;
      if (sharedAnimator != null) mesh.animator = sharedAnimator;
      results.add(mesh);
    }

    return results;
  }

  /// Creates a deep copy of this mesh instance suitable for independent animation.
  /// Heavy resources like [geom] and [mtr] are shared, while [skin], [animator],
  /// and skeletal [nodes] are duplicated.
  M3Mesh clone() {
    final Map<GltfNode, GltfNode> nodeCloneMap = {};
    final List<GltfNode>? clonedNodes = nodes?.map((n) {
      final cn = n.clone();
      nodeCloneMap[n] = cn;
      return cn;
    }).toList();

    final clonedSkin = skin != null && clonedNodes != null
        ? skin!.clone((skin!.jointNodes as List<GltfNode>).map((n) => nodeCloneMap[n]!).toList())
        : null;

    final clonedMesh = M3Mesh(geom, material: mtr, skin: clonedSkin);
    clonedMesh.initMatrix.setFrom(initMatrix);
    clonedMesh.nodes = clonedNodes;

    if (animator != null && clonedNodes != null) {
      final clonedNodeMap = {for (int i = 0; i < clonedNodes.length; i++) i: clonedNodes[i]};
      clonedMesh.animator = M3Animator(animator!.animations, clonedNodeMap, allNodes: clonedNodes);
      clonedMesh.animator!.playRate = animator!.playRate;
    }

    return clonedMesh;
  }
}
