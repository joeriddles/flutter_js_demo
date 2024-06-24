import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter_js_demo/js.dart' as js;
import 'package:flutter_js_demo/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_utils.dart' as test_utils;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("test MIDI", (WidgetTester tester) async {
    // Arrange
    js.onMidiAccess = ((JSObject midiAccessFromJs) {
      midiAccess = midiAccessFromJs;
    }).toJS;

    await tester.pumpWidget(const MyApp());
    await test_utils.takeScreenShot(
      binding: binding,
      tester: tester,
      screenShotName: "midi_pre",
    );

    // Act
    final fab = find.byKey(const Key('refresh'));
    final expectedFinder = find.text("[object MIDIAccess]");

    await test_utils.pumpUntilFound(
      tester,
      find.text("[object MIDIAccess]"),
      action: () async {
        await tester.tap(fab);
        await tester.pumpAndSettle();
      },
      timeout: const Duration(seconds: 60),
    );

    // Assert
    await test_utils.takeScreenShot(
      binding: binding,
      tester: tester,
      screenShotName: "midi_post",
    );

    expect(expectedFinder, findsOneWidget);
  });
}
