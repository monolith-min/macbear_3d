import 'package:flutter_test/flutter_test.dart';
import 'package:m3_video_bridge/m3_video_bridge.dart';
import 'package:m3_video_bridge/m3_video_bridge_platform_interface.dart';
import 'package:m3_video_bridge/m3_video_bridge_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockM3VideoBridgePlatform
    with MockPlatformInterfaceMixin
    implements M3VideoBridgePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final M3VideoBridgePlatform initialPlatform = M3VideoBridgePlatform.instance;

  test('$MethodChannelM3VideoBridge is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelM3VideoBridge>());
  });

  test('registerSurface', () async {
    // M3VideoBridge m3VideoBridgePlugin = M3VideoBridge();
    // String? version = await m3VideoBridgePlugin.getPlatformVersion();
    // expect(version, '42');
    // Since M3VideoBridge uses static methods now, we just check they exist.
    expect(M3VideoBridge.updateSurface(textureId: 0), completes);
  });
}
