// The sign-in page's drawn marks: the social pills carry each provider's
// official mark (Google first, Apple + Facebook under "Other methods"),
// untinted, and the prefix box draws Kuwait's flag (never mirrored) instead
// of the flag emoji.
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
import 'package:hero_mart/src/core/design/hero_assets.dart';
import 'package:hero_mart/src/core/responsive/app_size.dart';
import 'package:hero_mart/src/core/widgets/brand_mark.dart';
import 'package:hero_mart/src/features/auth/domain/entities/phone_number.dart';
import 'package:hero_mart/src/features/auth/presentation/widgets/login/login_prefix_box.dart';
import 'package:hero_mart/src/features/auth/presentation/widgets/login/login_social_button.dart';
import 'package:hero_mart/src/features/auth/presentation/widgets/login/login_social_section.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The [BrandMark] inside the social pill labelled [label].
Finder _markOf(String label) => find.descendant(
  of: find.widgetWithText(LoginSocialButton, label),
  matching: find.byType(BrandMark),
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

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );

  testWidgets('the social pills show the official marks, untinted', (
    tester,
  ) async {
    await pump(tester, const LoginSocialSection(firstCascadeIndex: 0));
    await tester.pumpAndSettle();

    expect(find.byType(LoginSocialButton), findsOneWidget);
    final google = tester.widget<BrandMark>(_markOf('Google'));
    expect(google.asset, HeroAssets.brandGoogle);
    expect(google.size, AppSize.s24);
    final googleImage = tester.widget<Image>(
      find.descendant(of: _markOf('Google'), matching: find.byType(Image)),
    );
    expect((googleImage.image as AssetImage).assetName, HeroAssets.brandGoogle);
    expect(googleImage.color, isNull);

    await tester.tap(find.text('auth.other_methods'.tr()));
    await tester.pumpAndSettle();

    final apple = 'auth.continue_with'.tr(namedArgs: {'provider': 'Apple'});
    final facebook = 'auth.continue_with'.tr(
      namedArgs: {'provider': 'Facebook'},
    );
    expect(
      tester.widget<BrandMark>(_markOf(apple)).asset,
      HeroAssets.brandApple,
    );
    expect(
      tester.widget<BrandMark>(_markOf(facebook)).asset,
      HeroAssets.brandFacebook,
    );
    final facebookSvg = tester.widget<SvgPicture>(
      find.descendant(of: _markOf(facebook), matching: find.byType(SvgPicture)),
    );
    expect(
      (facebookSvg.bytesLoader as SvgAssetLoader).assetName,
      HeroAssets.brandFacebook,
    );
    expect(facebookSvg.colorFilter, isNull);
  });

  testWidgets('the prefix box draws the Kuwait flag, never mirrored, and no '
      'flag emoji', (tester) async {
    await pump(
      tester,
      LoginPrefixBox(onTap: () {}),
      direction: TextDirection.rtl,
    );
    await tester.pump();

    // An official mark: drawn through BrandMark, never tinted.
    expect(
      tester.widget<BrandMark>(find.byType(BrandMark)).asset,
      HeroAssets.flagKuwait,
    );
    final flag = tester.widget<SvgPicture>(find.byType(SvgPicture));
    expect(
      (flag.bytesLoader as SvgAssetLoader).assetName,
      HeroAssets.flagKuwait,
    );
    expect(flag.matchTextDirection, isFalse);
    expect(flag.colorFilter, isNull);
    expect(flag.width, AppSize.s20);
    expect(flag.height, AppSize.s10);
    expect(find.text(PhoneNumber.kuwaitDialCode), findsOneWidget);
    expect(find.textContaining('🇰🇼'), findsNothing);
  });
}
