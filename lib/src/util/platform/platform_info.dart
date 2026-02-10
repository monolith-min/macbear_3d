// 1. 預設匯入 native: 編譯環境有 dart.library.io (Mobile/Desktop)
import 'platform_info_native.dart'
    // 2. 如果編譯環境有 dart.library.js_interop (Web)，改用 web 版
    if (dart.library.js_interop) 'platform_info_web.dart';

// Macbear3D engine
import '../../../macbear_3d.dart';

class PlatformInfo {
  static String getOS() {
    return getPlatformName();
  }

  static const Map<int, String> _glParamNames = {
    WebGL.MAX_TEXTURE_IMAGE_UNITS: "MAX_TEXTURE_IMAGE_UNITS",
    WebGL.MAX_VERTEX_TEXTURE_IMAGE_UNITS: "MAX_VERTEX_TEXTURE_IMAGE_UNITS",
    WebGL.MAX_TEXTURE_SIZE: "MAX_TEXTURE_SIZE",
    WebGL.MAX_CUBE_MAP_TEXTURE_SIZE: "MAX_CUBE_MAP_TEXTURE_SIZE",
    WebGL.MAX_VERTEX_ATTRIBS: "MAX_VERTEX_ATTRIBS",
    WebGL.MAX_VERTEX_UNIFORM_VECTORS: "MAX_VERTEX_UNIFORM_VECTORS",
    WebGL.MAX_VARYING_VECTORS: "MAX_VARYING_VECTORS",
    WebGL.MAX_FRAGMENT_UNIFORM_VECTORS: "MAX_FRAGMENT_UNIFORM_VECTORS",
    WebGL.MAX_SAMPLES: "MAX_SAMPLES",
    WebGL.MAX_COMBINED_TEXTURE_IMAGE_UNITS: "MAX_COMBINED_TEXTURE_IMAGE_UNITS",
    WebGL.SCISSOR_BOX: "SCISSOR_BOX",
    WebGL.VIEWPORT: "VIEWPORT",
    WebGL.MAX_TEXTURE_MAX_ANISOTROPY_EXT: "MAX_TEXTURE_MAX_ANISOTROPY_EXT",
    WebGL.MAX_UNIFORM_BUFFER_BINDINGS: "MAX_UNIFORM_BUFFER_BINDINGS",
  };

  static void checkGLExtensions() {
    final gl = M3AppEngine.instance.renderEngine.gl;

    _glParamNames.forEach((key, name) {
      final val = gl.getParameter(key);
      debugPrint("$name = $val");
    });

    getGLExtensions();
  }
}
