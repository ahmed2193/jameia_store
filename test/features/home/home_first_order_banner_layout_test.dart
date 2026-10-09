// The first-order bar laid out with the app's real fonts, in English and
// Arabic, on narrow to wide phones and at a larger text size: one line, no
// overflow, the rider on the start side and the chevron on the end side in
// both directions. With FIRST_ORDER_SHOTS_OUT set, each layout is also
// saved as a PNG there (for eyeballing against the reference).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_theme.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_first_order_banner.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_first_order_chevron.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_first_order_headline.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_first_order_rider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Map<String, List<String>> _fonts = {
  'NotoSans': [
    'NotoSans-Regular.ttf',
    'NotoSans-Medium.ttf',
    'NotoSans-SemiBold.ttf',
    'NotoSans-Bold.ttf',
  ],
  'NotoSansArabicUI': [
    'NotoSansArabicUI-Regular.ttf',
    'NotoSansArabicUI-Medium.ttf',
    'NotoSansArabicUI-SemiBold.ttf',
    'NotoSansArabicUI-Bold.ttf',
  ],
  'HeroIcons': ['hero_icons.ttf'],
};

/// The shell's tab bar height under the bar, for the shot's context.
const double _navHeight = 56;

void main() {
  final out = Platform.environment['FIRST_ORDER_SHOTS_OUT'];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final entry in _fonts.entries) {
      final loader = FontLoader(entry.key);
      for (final file in entry.value) {
        loader.addFont(rootBundle.load('assets/fonts/$file'));
      }
      await loader.load();
    }
  });

  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  for (final language in ['en', 'ar']) {
    for (final width in [320.0, 360.0, 412.0]) {
      for (final scale in [1.0, 1.3]) {
        testWidgets(
          '$language · $width dp · text ×$scale: one line, in place',
          (tester) async {
            tester.view
              ..physicalSize = Size(width, 200)
              ..devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            final shot = GlobalKey();
            await tester.runAsync(() async {
              await tester.pumpWidget(
                EasyLocalization(
                  supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
                  path: 'assets/i18n',
                  fallbackLocale: const Locale('en'),
                  startLocale: Locale(language),
                  saveLocale: false,
                  child: Builder(
                    builder: (context) => MaterialApp(
                      theme: AppTheme.light,
                      locale: context.locale,
                      supportedLocales: context.supportedLocales,
                      localizationsDelegates: context.localizationDelegates,
                      home: MediaQuery(
                        data: MediaQueryData(
                          size: Size(width, 200),
                          textScaler: TextScaler.linear(scale),
                        ),
                        child: Scaffold(
                          backgroundColor: Colors.white,
                          body: Align(
                            alignment: Alignment.bottomCenter,
                            child: RepaintBoundary(
                              key: shot,
                              child: ColoredBox(
                                color: Colors.white,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    HomeFirstOrderBanner(onTap: () {}),
                                    const SizedBox(height: _navHeight),
                                  ],
                                ),
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
            await frames(tester);

            expect(tester.takeException(), isNull, reason: 'no overflow');
            final bar = tester.getRect(find.byType(HomeFirstOrderBanner));
            final rider = tester.getRect(find.byType(HomeFirstOrderRider));
            final chevron = tester.getRect(find.byType(HomeFirstOrderChevron));
            final line = tester.getRect(find.byType(HomeFirstOrderHeadline));
            final rtl = language == 'ar';
            // Start side → line → end side, mirrored in Arabic.
            if (rtl) {
              expect(rider.right, greaterThan(line.right));
              expect(chevron.left, lessThan(line.left));
            } else {
              expect(rider.left, lessThan(line.left));
              expect(chevron.right, greaterThan(line.right));
            }
            expect(line.left, greaterThanOrEqualTo(bar.left));
            expect(line.right, lessThanOrEqualTo(bar.right));

            if (out == null) return;
            await tester.runAsync(() async {
              final boundary =
                  shot.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final image = await boundary.toImage(pixelRatio: 2);
              final png = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              image.dispose();
              File('$out/bar-$language-${width.toInt()}-x$scale.png')
                ..createSync(recursive: true)
                ..writeAsBytesSync(png!.buffer.asUint8List());
            });
          },
        );
      }
    }
  }
}
