// 在最新的 Flutter 中建議使用 package:web 或 dart:js_interop
import 'package:flutter/foundation.dart';

String getPlatformName() {
  return 'Browser';
}

void getGLExtensions() {
  debugPrint('${getPlatformName()} unsupport "getStringi"');
}
