import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void setupGoldenComparator() {
  VmServiceProxyGoldenFileComparator.useIfRunningOnDevice();
}

extension ScreenshotCapture on WidgetTester {
  Future<void> takeAndCompareScreenshot({
    required IntegrationTestWidgetsFlutterBinding binding,
    required String device,
    required String name,
  }) async {
    await pumpAndSettle();
    await pump();
    final bytes = await binding.takeScreenshot(name);
    final path = 'goldens/$device/$name.png';
    await expectLater(bytes, matchesGoldenFile(path));
  }
}
