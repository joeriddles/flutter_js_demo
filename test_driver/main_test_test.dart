import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async => integrationDriver(
        onScreenshot: (screenshotName, screenshotBytes, [args]) async {
      final filepath = 'screenshots/$screenshotName.png';
      final File image = await File(filepath).create(recursive: true);
      image.writeAsBytesSync(screenshotBytes);
      // ignore: avoid_print
      print('Screenshot saved to: $filepath');
      return true;
    });
