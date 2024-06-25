import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';
import 'package:webkit_inspection_protocol/webkit_inspection_protocol.dart';

Future<void> main() async {
  final chromeConnection = ChromeConnection('localhost');
  final chromeTab = (await chromeConnection.getTabs()).first;
  final wipConnection = await chromeTab.connect();
  final wipPage = WipPage(wipConnection);

  final versionResponse = await wipPage.sendCommand("Browser.getVersion");
  print(versionResponse.toString());

  final permissionResponse =
      await wipPage.sendCommand("Browser.grantPermissions", params: {
    'permissions': [
      'audioCapture',
      'videoCapture',
      'midi',
      // 'midiSysex',
    ]
  });
  print(permissionResponse.toString());

  await integrationDriver(
      onScreenshot: (screenshotName, screenshotBytes, [args]) async {
    final filepath = 'screenshots/$screenshotName.png';
    final File image = await File(filepath).create(recursive: true);
    image.writeAsBytesSync(screenshotBytes);
    // ignore: avoid_print
    print('Screenshot saved to: $filepath');
    return true;
  });
}
