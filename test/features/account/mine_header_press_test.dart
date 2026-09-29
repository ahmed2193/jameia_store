// I15a — the Mine header answers a finger (App A Mine P1): its avatar and
// name dip with the one press language while the backdrop holds still; the
// scan action presses by itself and the header then stays still; reduced
// motion drops the dip.
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/mine/mine_header.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/mine/mine_header_metrics.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/mine/mine_header_press_dip.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/mine/mine_scan_action.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  const metrics = MineHeaderMetrics(
    topInset: 0,
    textScaler: TextScaler.noScaling,
    isGuest: true,
  );

  Future<void> pumpHeader(WidgetTester tester, {bool reduced = false}) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          saveLocale: false,
          child: Builder(
            builder: (context) => MaterialApp(
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              home: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(disableAnimations: reduced),
                  child: Scaffold(
                    body: SizedBox(
                      height: metrics.maxExtent,
                      child: const MineHeader(
                        customer: null,
                        metrics: metrics,
                        shrinkOffset: 0,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();
  }

  List<double> dips(WidgetTester tester) => [
    for (final element
        in find
            .descendant(
              of: find.byType(MineHeaderPressDip),
              matching: find.byType(AnimatedScale),
            )
            .evaluate())
      (element.widget as AnimatedScale).scale,
  ];

  testWidgets('a press dips the avatar and the name, not the backdrop', (
    tester,
  ) async {
    await pumpHeader(tester);
    expect(dips(tester), [1.0, 1.0]);

    final press = await tester.startGesture(
      tester.getCenter(find.text('profile.sign_in_subtitle'.tr())),
    );
    await tester.pump(AppMotion.microPop);
    expect(dips(tester), [AppMotion.pressedScale, AppMotion.pressedScale]);
    // The header as a whole is not scaled.
    expect(
      find.ancestor(
        of: find.byType(MineHeaderPressDip).first,
        matching: find.byWidgetPredicate(
          (widget) => widget is AnimatedScale && widget.scale != 1,
        ),
      ),
      findsNothing,
    );

    await press.cancel();
    await tester.pump(AppMotion.fast);
    expect(dips(tester), [1.0, 1.0]);
  });

  testWidgets('the scan action presses alone', (tester) async {
    await pumpHeader(tester);
    final press = await tester.startGesture(
      tester.getCenter(find.byType(MineScanAction)),
    );
    await tester.pump(AppMotion.microPop);
    expect(dips(tester), [1.0, 1.0]);
    await press.cancel();
    await tester.pump(AppMotion.fast);
  });

  testWidgets('reduced motion: no dip', (tester) async {
    await pumpHeader(tester, reduced: true);
    final press = await tester.startGesture(
      tester.getCenter(find.text('profile.sign_in_subtitle'.tr())),
    );
    await tester.pump(AppMotion.microPop);
    expect(dips(tester), [1.0, 1.0]);
    await press.cancel();
    await tester.pump();
  });
}
