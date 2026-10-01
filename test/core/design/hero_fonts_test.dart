import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_text_styles.dart';
import 'package:hero_mart/src/config/theme/font_licenses.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('typography', () {
    test('body text is Noto Sans with the Arabic UI face behind it', () {
      final style = AppTextStyles.bodyMedium;
      expect(style.fontFamily, 'NotoSans');
      expect(style.fontFamilyFallback, ['NotoSansArabicUI']);
    });

    test('prices use HeroDigits and fall back to the body faces', () {
      final style = AppTextStyles.digits(16);
      expect(style.fontFamily, 'HeroDigits');
      // HeroDigits holds only digits and separators: letters and Arabic
      // come from the body faces, never from the platform font.
      expect(style.fontFamilyFallback, ['NotoSans', 'NotoSansArabicUI']);
    });

    test('pubspec bundles the fonts the styles name, and no copied font', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final family in [
        'NotoSans',
        'NotoSansArabicUI',
        'HeroDigits',
        'HeroIcons',
      ]) {
        expect(pubspec, contains('family: $family\n'), reason: family);
      }
      for (final gone in ['MTDigit', 'wm_c_iconfont', 'Hero-Regular.otf']) {
        expect(pubspec, isNot(contains(gone)), reason: gone);
      }
      for (final weight in ['Regular', 'Medium', 'Bold']) {
        expect(
          File('assets/fonts/HeroDigits-$weight.ttf').existsSync(),
          isTrue,
        );
      }
    });
  });

  test(
    'the OFL licences of the bundled fonts reach the licence registry',
    () async {
      FontLicenses.register();
      final packages = <String>{};
      await for (final entry in LicenseRegistry.licenses) {
        packages.addAll(entry.packages);
      }
      expect(
        packages,
        containsAll(<String>[
          'Fredoka (HeroDigits, the Hero wordmarks)',
          'Baloo Bhaijaan 2 (the Arabic Hero wordmark)',
          'Noto Sans',
          'Noto Sans Arabic UI',
        ]),
      );
    },
  );
}
