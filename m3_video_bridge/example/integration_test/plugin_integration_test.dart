// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:m3_video_bridge/m3_video_bridge.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    // Verify that the registerSurface method exists (mental check, we don't have a full mock here)
    // For now, we just verify the plugin loads without crashing.
    expect(M3VideoBridge.updateSurface(textureId: 0), completes);
  });
}
