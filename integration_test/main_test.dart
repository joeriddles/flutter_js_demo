import 'package:flutter/material.dart';
import 'package:flutter_js_demo/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_utils.dart' as test_utils;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("test MIDI", (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(const MyApp());
    await test_utils.takeScreenShot(
      binding: binding,
      tester: tester,
      screenShotName: "midi_pre",
    );

    // Act
    final expectedFinder = find.text("[object MIDIAccess]");
    final errorFinder = find.textContaining(RegExp(r'Error:.*'));

    final requestPermissionsButton = find.text('Request permissions');
    await tester.tap(requestPermissionsButton);

    await test_utils.pumpUntilAnyFound(
      tester,
      [expectedFinder, errorFinder],
      action: tester.pumpAndSettle,
      timeout: const Duration(seconds: 60),
    );

    // Assert
    await test_utils.takeScreenShot(
      binding: binding,
      tester: tester,
      screenShotName: "midi_post",
    );

    if (errorFinder.hasFound && errorFinder.found.isNotEmpty) {
      final errorMessage = (errorFinder.found.single.widget as Text).data;
      fail('Failed to access MIDI with error: $errorMessage');
    }
    expect(expectedFinder.found.length, 1, reason: 'Could not find [object MIDIAccess]');
  });
}
