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

typedef EglGetCurrentDisplayC = Pointer<Void> Function();
typedef EglGetCurrentDisplayDart = Pointer<Void> Function();

typedef EglQueryStringC = Pointer<Uint8> Function(Pointer<Void> display, Int32 name);
typedef EglQueryStringDart = Pointer<Uint8> Function(Pointer<Void> display, int name);

void getEGLExtensions() {
  final eglLib = _loadEGLLib();
  if (eglLib == null) {
    debugPrint("EGL library not found");
    return;
  }

  // ignore: constant_identifier_names
  const int EGL_EXTENSIONS = 0x3055;
  try {
    final EglGetCurrentDisplayDart eglGetCurrentDisplay = eglLib
        .lookup<NativeFunction<EglGetCurrentDisplayC>>('eglGetCurrentDisplay')
        .asFunction();
    final EglQueryStringDart eglQueryString = eglLib
        .lookup<NativeFunction<EglQueryStringC>>('eglQueryString')
        .asFunction();

    final display = eglGetCurrentDisplay();
    debugPrint("EGL Display: $display");

    // 1. Client Extensions (Display is EGL_NO_DISPLAY = nullptr)
    final clientExtsPtr = eglQueryString(nullptr, EGL_EXTENSIONS);
    if (clientExtsPtr.address != 0) {
      debugPrint("EGL Client Extensions:");
      _printExtensionList(clientExtsPtr.cast<Utf8>().toDartString());
    }

    // 2. Display Extensions
    if (display.address != 0) {
      final displayExtsPtr = eglQueryString(display, EGL_EXTENSIONS);
      if (displayExtsPtr.address != 0) {
        debugPrint("EGL Display Extensions:");
        _printExtensionList(displayExtsPtr.cast<Utf8>().toDartString());
      }
    }
  } catch (e) {
    debugPrint("Error querying EGL extensions: $e");
  } finally {
    eglLib.close();
  }
}

void _printExtensionList(String extensions) {
  final list = extensions.split(' ');
  for (var i = 0; i < list.length; i++) {
    final ext = list[i].trim();
    if (ext.isNotEmpty) {
      debugPrint("- #$i = $ext");
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

DynamicLibrary? _loadEGLLib() {
  if (Platform.isMacOS || Platform.isIOS) {
    try {
      return DynamicLibrary.open('libEGL.framework/libEGL');
    } catch (e) {
      return DynamicLibrary.open('libEGL');
    }
  } else if (Platform.isAndroid) {
    try {
      return DynamicLibrary.open('libEGL_angle.so');
    } catch (e) {
      return DynamicLibrary.open('libEGL.so');
    }
  } else if (Platform.isWindows) {
    try {
      return DynamicLibrary.open('libEGL.dll');
    } catch (e) {
      return DynamicLibrary.open('libEGL_angle.dll');
    }
  }
  return null;
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
