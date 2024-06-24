import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

Future<void> main() async => integrationDriver(
        onScreenshot: (screenshotName, screenshotBytes, [args]) async {
      // This is super hacky to use a screenshot callback for something else...
      if (screenshotName == "DEBUG") {
        // Wip (Webkit Inspection Protocol)
        final chromeConnection = ChromeConnection('localhost');
        final chromeTab = (await chromeConnection.getTabs()).first;
        final wipConnection = await chromeTab.connect();
        final wipPage = WipPage(wipConnection);
        final response = await wipPage.sendCommand(
          "Browser.setPermission",
          params: {
            'permission': {
              'name': 'midi',
              'sysex': true,
            },
            'setting': 'granted',
          },
        );
        print('WipResponse: ${response.toString()}');
        return true;
      }

      final filepath = 'screenshots/$screenshotName.png';
      final File image = await File(filepath).create(recursive: true);
      image.writeAsBytesSync(screenshotBytes);
      // ignore: avoid_print
      print('Screenshot saved to: $filepath');
      return true;
    });
