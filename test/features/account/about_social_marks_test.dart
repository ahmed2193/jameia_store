// About's social tiles show each network's official mark (Facebook,
// Instagram, X), untinted on a neutral disc — no Material stand-in glyphs.
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/core/design/hero_assets.dart';
import 'package:hero_mart/src/core/widgets/brand_mark.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/about/about_follow_section.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/about/about_social_chip.dart';
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

  testWidgets('each tile draws its network mark untinted on a neutral disc', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AboutFollowSection())),
    );
    await tester.pump();

    expect(find.byType(AboutSocialChip), findsNWidgets(3));
    final marks = tester
        .widgetList<BrandMark>(find.byType(BrandMark))
        .map((mark) => mark.asset);
    expect(marks, [
      HeroAssets.brandFacebook,
      HeroAssets.brandInstagram,
      HeroAssets.brandX,
    ]);
    for (final svg in tester.widgetList<SvgPicture>(find.byType(SvgPicture))) {
      expect(svg.colorFilter, isNull);
    }
    expect(find.byType(Icon), findsNothing);

    final discs = tester.widgetList<DecoratedBox>(
      find.ancestor(
        of: find.byType(BrandMark),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect(
      discs.map((box) => (box.decoration as BoxDecoration).color),
      contains(AppColors.smallBackground),
    );
  });
}
