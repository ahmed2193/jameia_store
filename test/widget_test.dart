// Smoke test for the JameiaMart.
//
// The app root (`JameiaApp`) needs the service locator + EasyLocalization booted
// before it can build, which is too heavy for a widget test. Instead we verify
// that the Jameia theme renders a core widget correctly — a fast sanity check
// that the design-token layer and shared widget catalog wire up.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jameia_mart/src/config/theme/app_theme.dart';
import 'package:jameia_mart/src/core/widgets/app_button.dart';

void main() {
  testWidgets(
    'AppButton renders its label and fires onPressed under Jameia theme',
    (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: AppButton(
              label: 'Place order',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Place order'), findsOneWidget);

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(tapped, isTrue);
    },
  );
}
