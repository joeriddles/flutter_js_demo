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

/// Pump for the duration of [timeout].
Future<void> pumpFor(
  WidgetTester tester,
  Duration timeout, {
  Function? action,
}) async {
  bool timerDone = false;
  final timer = Timer(timeout, () => timerDone = true);
  while (timerDone != true) {
    await tester.pump();
    if (action != null) {
      await action();
    }
    await Future.delayed(const Duration(milliseconds: 100));
  }

  timer.cancel();
}

/// Pump until [finder] is found or the timer runs out.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
  Function? action,
}) async {
  bool timerDone = false;
  final timer = Timer(timeout, () => timerDone = true);
  bool found = false;
  while (timerDone != true) {
    await tester.pump();

    found = tester.any(finder);
    if (found) {
      timerDone = true;
    }

    if (action != null) {
      await action();
    }
  }

  timer.cancel();
  expect(found, true, reason: 'Failed to find in the time limit.');
}
