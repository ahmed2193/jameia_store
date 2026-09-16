// Smoke test for the KeeTa clone.
//
// The app root (`KeetaApp`) needs the service locator + EasyLocalization booted
// before it can build, which is too heavy for a widget test. Instead we verify
// that the KeeTa theme renders a core widget correctly — a fast sanity check
// that the design-token layer and shared widget catalog wire up.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jameia_mart/core/theme/app_theme.dart';
import 'package:jameia_mart/core/widgets/app_button.dart';

void main() {
  testWidgets('AppButton renders its label and fires onPressed under KeeTa theme',
      (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: AppButton(label: 'Place order', onPressed: () => tapped = true),
        ),
      ),
    );

    expect(find.text('Place order'), findsOneWidget);

    await tester.tap(find.byType(AppButton));
    await tester.pump();

    expect(tapped, isTrue);
  });
}
