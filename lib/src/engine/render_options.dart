part of 'render_engine.dart';

/// Rendering options for the engine (wireframe, helpers, shadows, FPS display).
class M3RenderOptions {
  // debug options
  M3DebugOptions debug = M3DebugOptions();
  // shader options
  M3ShaderOptions shader = M3ShaderOptions();
  bool shadows = true;
}

class M3DebugOptions {
  bool wireframe = false;
  bool showHelpers = false;
  bool showStats = true;
  bool showPhysicsStats = false;
}

// GLSL options
class M3ShaderOptions {
  bool _perPixel = false; // per-pixel lighting
  bool _cartoon = false; // cartoon shading
  bool pcf = true; // shadow PCF

  // --- perPixel ---
  bool get perPixel => _perPixel;
  set perPixel(bool v) {
    _perPixel = v;

    // perPixel 關閉時，cartoon 一定要關
    if (!_perPixel && _cartoon) {
      _cartoon = false;
    }
  }

  // --- cartoon ---
  bool get cartoon => _cartoon;
  set cartoon(bool v) {
    _cartoon = v;

    // cartoon 開啟時，自動強制 perPixel
    if (_cartoon && !_perPixel) {
      _perPixel = true;
    }
  }
}

/// Rendering statistics
class M3RenderStats {
  int frames = 0;
  int vertices = 0;
  int triangles = 0;
  int entities = 0;
  int culling = 0;
  int reflection = 0;

  void reset() {
    vertices = 0;
    triangles = 0;
    entities = 0;
    culling = 0;
    reflection = 0;
  }

  @override
  String toString() {
    return '''
${frames.toString().padLeft(6)}
mesh:$entities/$culling
reflect:$reflection
 tri:$triangles
vert:$vertices''';
  }
}
