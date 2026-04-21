// Macbear3D engine
import '../m3_internal.dart';

/// Represents a single mesh draw call data for sorting and batching.
class M3RenderItem {
  final M3Entity entity;
  final M3Mesh mesh;
  final Matrix4 worldMatrix;
  final double depth;

  M3RenderItem({
    required this.entity,
    required this.mesh,
    required this.worldMatrix,
    required this.depth,
  });

  /// Priority for sorting opaque objects.
  int get opaqueSortKey {
    return mesh.mtr.renderOrder;
  }
}

/// A queue of render items to be processed in a specific order.
class M3RenderQueue {
  final List<M3RenderItem> items = [];

  void clear() => items.clear();

  void add(M3RenderItem item) => items.add(item);

  bool get isEmpty => items.isEmpty;

  /// Sort opaque items: Front-to-Back for Early-Z optimization.
  void sortOpaque() {
    items.sort((a, b) {
      if (a.mesh.mtr.renderOrder != b.mesh.mtr.renderOrder) {
        return a.mesh.mtr.renderOrder.compareTo(b.mesh.mtr.renderOrder);
      }
      return a.depth.compareTo(b.depth);
    });
  }

  /// Sort transparent items: Back-to-Front for correct alpha blending.
  void sortTransparent() {
    items.sort((a, b) {
      if (a.mesh.mtr.renderOrder != b.mesh.mtr.renderOrder) {
        return a.mesh.mtr.renderOrder.compareTo(b.mesh.mtr.renderOrder);
      }
      return b.depth.compareTo(a.depth);
    });
  }
}

/// Managed list of render queues for different rendering passes.
class M3RenderPipeline {
  final M3RenderQueue opaque = M3RenderQueue();
  final M3RenderQueue transparent = M3RenderQueue();

  void clear() {
    opaque.clear();
    transparent.clear();
  }

  /// Collects a mesh into the appropriate queue based on its material.
  void collect(M3Entity entity, M3Mesh mesh, Matrix4 worldMat, double depth) {
    final item = M3RenderItem(
      entity: entity,
      mesh: mesh,
      worldMatrix: worldMat,
      depth: depth,
    );

    if (mesh.mtr.alphaMode == M3AlphaMode.blend) {
      transparent.add(item);
    } else {
      opaque.add(item);
    }
  }

  void sort() {
    opaque.sortOpaque();
    transparent.sortTransparent();
  }
}
