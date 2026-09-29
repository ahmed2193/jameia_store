// B1-05 (docs/motion §9.5 Haptics map): one haptic per gesture, of the kind
// the map names — commit buttons tap, destructive confirms warn (on the
// confirm only), cart "+" clicks and "−" taps, and nothing reaches the
// platform while muted.
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/core/motion/haptics.dart';
import 'package:hero_mart/src/core/widgets/app_button.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_list/address_delete_dialog.dart';
import 'package:hero_mart/src/features/cart/presentation/widgets/cart/cart_qty_step_button.dart';
import 'package:hero_mart/src/features/product_details/presentation/widgets/pdp_step_button.dart';
import 'package:hero_mart/src/features/store_mode/presentation/widgets/pro_confirm_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _light = 'HapticFeedbackType.lightImpact';
const String _click = 'HapticFeedbackType.selectionClick';
const String _heavy = 'HapticFeedbackType.heavyImpact';

List<String?> _recordHaptics(WidgetTester tester) {
  final calls = <String?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String?);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

Future<void> _pump(WidgetTester tester, Widget child) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  setUp(Haptics.debugReset);

  group('AppButton', () {
    testWidgets('a commit press taps once', (tester) async {
      final calls = _recordHaptics(tester);
      var presses = 0;
      await _pump(tester, AppButton(label: 'Save', onPressed: () => presses++));

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(presses, 1);
      expect(calls, [_light]);
    });

    testWidgets('a destructive confirm warns once, instead of the tap', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      await _pump(
        tester,
        AppButton(
          label: 'Delete',
          haptic: HapticKind.warning,
          onPressed: () {},
        ),
      );

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(calls, [_heavy]);
    });

    testWidgets('a disabled button is silent', (tester) async {
      final calls = _recordHaptics(tester);
      await _pump(
        tester,
        AppButton(label: 'Save', enabled: false, onPressed: () {}),
      );

      await tester.tap(find.byType(AppButton), warnIfMissed: false);
      await tester.pump();

      expect(calls, isEmpty);
    });

    testWidgets('muted: the press reaches no vibrator', (tester) async {
      final calls = _recordHaptics(tester);
      Haptics.enabled = false;
      await _pump(tester, AppButton(label: 'Save', onPressed: () {}));

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(calls, isEmpty);
    });
  });

  group('destructive confirms', () {
    testWidgets('delete address: the confirm warns once, cancel is silent', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => const AddressDeleteDialog(),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(calls, isEmpty, reason: 'opening the dialog never buzzes');

      await tester.tap(find.byType(AppOutlineButton));
      await tester.pumpAndSettle();
      expect(calls, isEmpty, reason: 'cancel is not destructive');

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppButton));
      await tester.pumpAndSettle();
      expect(calls, [_heavy]);
    });

    Future<void> pumpProDialog(
      WidgetTester tester, {
      required bool destructive,
    }) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, _) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<bool>(
                  context: context,
                  builder: (_) => ProConfirmDialog(
                    title: 'Title',
                    message: 'Message',
                    confirmLabel: 'Go ahead',
                    isDestructive: destructive,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('cancel Pro renewal: the destructive confirm warns', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      await pumpProDialog(tester, destructive: true);
      expect(calls, isEmpty);

      await tester.tap(find.text('Go ahead'));
      await tester.pumpAndSettle();

      expect(calls, [_heavy]);
      expect(find.byType(ProConfirmDialog), findsNothing);
    });

    testWidgets('a non-destructive Pro confirm stays silent', (tester) async {
      final calls = _recordHaptics(tester);
      await pumpProDialog(tester, destructive: false);

      await tester.tap(find.text('Go ahead'));
      await tester.pumpAndSettle();

      expect(calls, isEmpty);
    });
  });

  group('quantity steppers', () {
    testWidgets('cart: "+" clicks, "−" taps — one haptic per press', (
      tester,
    ) async {
      final calls = _recordHaptics(tester);
      await _pump(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CartQtyStepButton(
              icon: Icons.remove_rounded,
              tooltip: 'less',
              removes: true,
              onTap: () {},
            ),
            CartQtyStepButton(
              icon: Icons.add_rounded,
              tooltip: 'more',
              onTap: () {},
            ),
          ],
        ),
      );

      await tester.tap(find.byTooltip('more'));
      await tester.pump();
      await tester.tap(find.byTooltip('less'));
      await tester.pump();

      expect(calls, [_click, _light]);
    });

    testWidgets('product page: "+" clicks, "−" taps', (tester) async {
      final calls = _recordHaptics(tester);
      await _pump(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            PdpStepButton(
              icon: Icons.remove_rounded,
              label: 'less',
              removes: true,
              onTap: () {},
            ),
            PdpStepButton(icon: Icons.add_rounded, label: 'more', onTap: () {}),
          ],
        ),
      );

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.remove_rounded));
      await tester.pump();

      expect(calls, [_click, _light]);
    });
  });

  testWidgets('a discard taps lightly, like a cart remove', (tester) async {
    final calls = _recordHaptics(tester);

    Haptics.discard();

    expect(calls, [_light]);
  });
}
