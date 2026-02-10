import 'dart:io';

// Macbear3D engine
import '../../../macbear_3d.dart';

String getPlatformName() {
  return Platform.operatingSystem; // Android, iOS, Windows, etc.
}

void getGLExtensions() {
  final gl = M3AppEngine.instance.renderEngine.gl;
  if (!kIsWeb) {
    for (int i = 0; i < 150; i++) {
      final s0 = gl.getStringi(WebGL.EXTENSIONS, i);
      debugPrint("GL [$i] = $s0");
      if (s0 == 'unnamed') {
        break;
      }
    }
  }
}
