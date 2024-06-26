import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Take a screenshot.
Future<void> takeScreenShot({
  required IntegrationTestWidgetsFlutterBinding binding,
  required WidgetTester tester,
  required String screenShotName,
}) async {
  if (kIsWeb) {
    await binding.takeScreenshot(screenShotName);
    return;
  } else if (Platform.isAndroid) {
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
  }
  await binding.takeScreenshot(screenShotName);
}

/// Pump until any of [finders] is found or the timer runs out.
///
/// [actions] are performed in between every pump, if not null.
Future<Finder> pumpUntilAnyFound(
  WidgetTester tester,
  List<Finder> finders, {
  Duration timeout = const Duration(seconds: 10),
  Function? action,
}) async {
  bool timerDone = false;
  final timer = Timer(timeout, () => timerDone = true);
  Finder? finder;
  Finder? foundFinder;
  while (timerDone != true) {
    for (var i = 0; i < finders.length; i++) {
      finder = finders[i];
      final found = tester.any(finder);
      if (found) {
        timerDone = true;
        foundFinder = finder;
        break;
      }
    }

    if (action != null) {
      await action();
    }
    await tester.pump();
  }

  timer.cancel();
  expect(foundFinder, isNotNull, reason: 'Failed to find $finder in the time limit.');
  return foundFinder!;
}
