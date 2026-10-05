// Driver that saves integration-test screenshots as PNG files.
// SCREENSHOT_DIR (default build/screenshots) chooses the output folder.
import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final dir = Directory(
    Platform.environment['SCREENSHOT_DIR'] ?? 'build/screenshots',
  )..createSync(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      File('${dir.path}/$name.png').writeAsBytesSync(bytes);
      return true;
    },
  );
}
