// The talabat basket-bar kit: the "View cart" card (basket + count, amount,
// delivery line), the sticker label (one Text, painted rim) and the sticker
// button (disabled / loading do not react).
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/widgets/cart_basket_badge.dart';
import 'package:jameia_mart/src/core/widgets/cart_bar_summary.dart';
import 'package:jameia_mart/src/core/widgets/sticker_button.dart';
import 'package:jameia_mart/src/core/widgets/sticker_rim_painter.dart';
import 'package:jameia_mart/src/core/widgets/sticker_text.dart';
import 'package:jameia_mart/src/core/widgets/view_cart_pill.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final raw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(raw) as Map<String, dynamic>),
    );
  });

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );

  group('ViewCartPill', () {
    testWidgets('basket with its count, amount, free delivery, "View cart"', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        ViewCartPill(
          count: 11,
          totalKd: 103.1,
          deliveryKd: 0,
          onTap: () => taps++,
        ),
      );

      expect(find.byType(CartBasketBadge), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
      expect(find.text('Free delivery'), findsOneWidget);
      expect(find.text('View cart'), findsOneWidget);
      expect(
        tester.getSize(find.byType(ViewCartPill)).height,
        greaterThanOrEqualTo(ViewCartPill.height),
      );

      await tester.tap(find.byType(ViewCartPill));
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 1);
    });

    testWidgets('a fee reads "KD 0.650 delivery"; no quote, no line', (
      tester,
    ) async {
      await pump(
        tester,
        const Column(
          children: [
            ViewCartPill(count: 1, totalKd: 2.25, deliveryKd: 0.65, onTap: _noop),
            ViewCartPill(count: 1, totalKd: 2.25, onTap: _noop),
          ],
        ),
      );

      expect(find.text('KD 0.650 delivery'), findsOneWidget);
      expect(find.text('Free delivery'), findsNothing);
    });
  });

  group('CartBarSummary', () {
    testWidgets('struck amount only beside a priced total', (tester) async {
      await pump(
        tester,
        const CartBarSummary(
          count: 3,
          amountKd: 4.75,
          struckKd: 6.75,
          deliveryKd: 0,
          placeholder: 'Updating…',
        ),
      );
      final semantics = tester.ensureSemantics();
      expect(find.bySemanticsLabel('KD 6.750'), findsOneWidget);

      await pump(
        tester,
        const CartBarSummary(
          count: 3,
          amountKd: null,
          struckKd: 6.75,
          placeholder: 'Updating…',
        ),
      );
      expect(find.text('Updating…'), findsOneWidget);
      expect(find.bySemanticsLabel('KD 6.750'), findsNothing);
      semantics.dispose();
    });
  });

  group('sticker kit', () {
    testWidgets('a sticker label is one Text with a painted rim', (
      tester,
    ) async {
      await pump(
        tester,
        const StickerText('Add to cart', style: TextStyle(fontSize: 20)),
      );

      expect(find.text('Add to cart'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is StickerRimPainter,
        ),
        findsOneWidget,
      );
    });

    testWidgets('disabled or loading, the button does not react', (
      tester,
    ) async {
      var taps = 0;
      Future<void> show({bool enabled = true, bool loading = false}) => pump(
        tester,
        StickerButton(
          label: 'Checkout',
          enabled: enabled,
          loading: loading,
          onPressed: () => taps++,
        ),
      );

      await show();
      await tester.tap(find.text('Checkout'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 1);

      await show(enabled: false);
      await tester.tap(find.text('Checkout'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 1);
      expect(find.byType(StickerText), findsNothing, reason: 'plain grey');

      await show(loading: true);
      expect(find.text('Checkout'), findsNothing);
      await tester.tap(find.byType(StickerButton));
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 1);
    });
  });
}

void _noop() {}
