import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart'; // 需要 pkg:ffi

// Macbear3D engine
import '../../../macbear_3d.dart';

String getPlatformName() {
  return Platform.operatingSystem; // Android, iOS, Windows, etc.
}

void getGLExtensions() {
  final gl = M3AppEngine.instance.renderEngine.gl;
  if (!kIsWeb) {
    int numExt = gl.getIntegerv(0x821D);
    for (int i = 0; i < numExt; i++) {
      final s0 = gl.getStringi(WebGL.EXTENSIONS, i);
      debugPrint("- #$i = $s0");
    }
  }
}

DynamicLibrary? _loadGLESv2Lib() {
  if (Platform.isMacOS || Platform.isIOS) {
    // 當 Framework 被正確 Embed 時，可以直接透過名稱載入
    // 系統會在 Frameworks 目錄中搜尋
    try {
      return DynamicLibrary.open('libGLESv2.framework/libGLESv2');
    } catch (e) {
      // 備用路徑
      return DynamicLibrary.open('libGLESv2');
    }
  } else if (Platform.isAndroid) {
    try {
      return DynamicLibrary.open('libGLESv2_angle.so');
    } catch (e) {
      // 備用路徑
      return null;
    }
  } else if (Platform.isWindows) {
    try {
      return DynamicLibrary.open('libGLESv2.dll');
    } catch (e) {
      return DynamicLibrary.open('libGLESv2_angle.dll');
    }
  }

  return null; // unsupported platform
}

// 定義 C 函式的簽名
typedef GLGetStringC = Pointer<Uint8> Function(Uint32 name);
typedef GLGetStringDart = Pointer<Uint8> Function(int name);

String safeGetString(Pointer<Uint8> ptr) {
  if (ptr.address == 0) return "Unknown";
  return ptr.cast<Utf8>().toDartString();
}

GraphicsInfo getGpuInfo() {
  final glesLib = _loadGLESv2Lib();
  if (glesLib == null) {
    return const GraphicsInfo(vendor: "None", renderer: "None", version: "None", shadingVersion: "None");
  }
  final GLGetStringDart glGetString = glesLib.lookup<NativeFunction<GLGetStringC>>('glGetString').asFunction();

  Pointer<Uint8> vendorPtr = glGetString(WebGL.VENDOR);
  Pointer<Uint8> rendererPtr = glGetString(WebGL.RENDERER);
  Pointer<Uint8> versionPtr = glGetString(WebGL.VERSION);
  Pointer<Uint8> shaderPtr = glGetString(WebGL.SHADING_LANGUAGE_VERSION);

  // 將 C 指標轉為 Dart String
  String vendor = safeGetString(vendorPtr);
  String renderer = safeGetString(rendererPtr);
  String version = safeGetString(versionPtr);
  String glslVer = safeGetString(shaderPtr);
  GraphicsInfo ret = GraphicsInfo(vendor: vendor, renderer: renderer, version: version, shadingVersion: glslVer);

  glesLib.close();
  return ret;
}
