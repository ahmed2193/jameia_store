// HeroIcon: the sticker look (ink line over the natural fill) for ink
// colours, one plain glyph for every other colour, a tone pair on request.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/core/design/hero_icon_fill_colors.dart';
import 'package:hero_mart/src/core/design/hero_icon_tone.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/widgets/hero_icon.dart';

Widget _host(
  Widget child, {
  HeroColors palette = HeroColors.light,
  IconThemeData? iconTheme,
}) {
  final Widget centred = Center(child: child);
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Theme(
      data: ThemeData(extensions: [palette]),
      child: iconTheme == null
          ? centred
          : IconTheme(data: iconTheme, child: centred),
    ),
  );
}

List<Icon> _icons(WidgetTester tester) =>
    tester.widgetList<Icon>(find.byType(Icon)).toList();

/// The colours the glyphs are actually painted in, bottom first.
List<Color?> _painted(WidgetTester tester) => tester
    .widgetList<RichText>(find.byType(RichText))
    .map((text) => text.text.style?.color)
    .toList();

void main() {
  group('sticker (ink colour)', () {
    testWidgets('draws the natural fill under the line in iconInk', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const HeroIcon(HeroIcons.bag, color: AppColors.primaryText, size: 32),
        ),
      );
      final [accent, line] = _icons(tester);
      expect(accent.icon, HeroIcons.bagAccent);
      expect(accent.color, AppColors.primary);
      expect(accent.size, 32);
      expect(line.icon, HeroIcons.bag);
      expect(line.color, AppColors.stickerOutline);
      expect(line.color, HeroColors.light.iconInk);
      expect(line.size, 32);
    });

    testWidgets('every ink colour turns into a sticker', (tester) async {
      for (final ink in HeroIcon.inkColors) {
        await tester.pumpWidget(_host(HeroIcon(HeroIcons.bell, color: ink)));
        final [accent, line] = _icons(tester);
        expect(accent.color, HeroIconFill.yellow.color, reason: '$ink');
        expect(line.color, AppColors.stickerOutline, reason: '$ink');
      }
    });

    testWidgets('the fill follows the icon (HeroIcons.fillOf)', (tester) async {
      await tester.pumpWidget(
        _host(const HeroIcon(HeroIcons.heart, color: AppColors.brandDeep)),
      );
      final [accent, _] = _icons(tester);
      expect(HeroIcons.fillOf(HeroIcons.heart), HeroIconFill.red);
      expect(accent.color, AppColors.accent1);
    });

    testWidgets('dark mode inks with the dark palette', (tester) async {
      await tester.pumpWidget(
        _host(
          HeroIcon(HeroIcons.chat, color: HeroColors.dark.primaryText),
          palette: HeroColors.dark,
        ),
      );
      final [accent, line] = _icons(tester);
      expect(accent.color, AppColors.brandLightBg);
      expect(line.color, HeroColors.dark.iconInk);
    });

    testWidgets('an icon without an accent draws its ink line only', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const HeroIcon(HeroIcons.close, color: AppColors.primaryText)),
      );
      final icons = _icons(tester);
      expect(icons, hasLength(1));
      expect(icons.single.icon, HeroIcons.close);
      expect(icons.single.color, AppColors.stickerOutline);
    });

    testWidgets('a directional icon flips both layers', (tester) async {
      await tester.pumpWidget(
        _host(const HeroIcon(HeroIcons.help, color: AppColors.primaryText)),
      );
      final [accent, line] = _icons(tester);
      expect(line.icon!.matchTextDirection, isTrue);
      expect(accent.icon!.matchTextDirection, isTrue);
    });
  });

  group('mono (any other colour)', () {
    for (final (name, color) in [
      ('white', AppColors.white),
      ('secondaryText', AppColors.secondaryText),
      ('disabledText', AppColors.disabledText),
      ('error', AppColors.error),
      ('proIndigo', AppColors.proIndigo),
      ('link', AppColors.link),
    ]) {
      testWidgets('$name → one glyph in that colour', (tester) async {
        await tester.pumpWidget(_host(HeroIcon(HeroIcons.bag, color: color)));
        final icons = _icons(tester);
        expect(icons, hasLength(1));
        expect(icons.single.icon, HeroIcons.bag);
        expect(icons.single.color, color);
      });
    }

    testWidgets('mono: true keeps an ink colour plain', (tester) async {
      await tester.pumpWidget(
        _host(
          const HeroIcon(
            HeroIcons.bag,
            color: AppColors.primaryText,
            mono: true,
          ),
        ),
      );
      final icons = _icons(tester);
      expect(icons, hasLength(1));
      expect(icons.single.color, AppColors.primaryText);
    });
  });

  group('tone', () {
    testWidgets('draws the tone pair instead of ink + fill', (tester) async {
      await tester.pumpWidget(
        _host(
          const HeroIcon(HeroIcons.wallet, tone: HeroIconTone.gold, size: 32),
        ),
      );
      final [accent, line] = _icons(tester);
      expect(accent.icon, HeroIcons.walletAccent);
      expect(accent.color, AppColors.proAmber);
      expect(line.icon, HeroIcons.wallet);
      expect(line.color, AppColors.primaryText);
      expect(line.size, 32);
    });

    testWidgets('wins over a mono colour', (tester) async {
      await tester.pumpWidget(
        _host(
          const HeroIcon(
            HeroIcons.bag,
            color: AppColors.white,
            tone: HeroIconTone.brand,
          ),
        ),
      );
      final [accent, line] = _icons(tester);
      expect(accent.color, AppColors.brandLightBg);
      expect(line.color, AppColors.brandDeep);
    });

    testWidgets('an icon without an accent draws the tone line only', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const HeroIcon(HeroIcons.close, tone: HeroIconTone.pro)),
      );
      final icons = _icons(tester);
      expect(icons, hasLength(1));
      expect(icons.single.color, AppColors.proIndigo);
    });

    test('every tone is an AppColors pair (SPEC "Colour")', () {
      final pairs = {
        for (final tone in HeroIconTone.values) tone: (tone.line, tone.accent),
      };
      expect(pairs, {
        HeroIconTone.brand: (AppColors.brandDeep, AppColors.brandLightBg),
        HeroIconTone.pro: (AppColors.proIndigo, AppColors.accentVioletLight),
        HeroIconTone.offer: (AppColors.accent1Dark, AppColors.accent1Light),
        HeroIconTone.gold: (AppColors.primaryText, AppColors.proAmber),
        HeroIconTone.info: (AppColors.link, AppColors.accentSkyLight),
        HeroIconTone.warm: (AppColors.accent3Dark, AppColors.accent4Light),
        HeroIconTone.neutral: (
          AppColors.primaryText,
          AppColors.smallBackground,
        ),
      });
    });
  });

  group('IconTheme', () {
    testWidgets('an ink IconTheme colour makes a sticker', (tester) async {
      await tester.pumpWidget(
        _host(
          const HeroIcon(HeroIcons.gift),
          iconTheme: const IconThemeData(color: AppColors.primaryText),
        ),
      );
      expect(_painted(tester), [AppColors.accent3, AppColors.stickerOutline]);
    });

    testWidgets('any other IconTheme colour paints one glyph in it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const HeroIcon(HeroIcons.gift),
          iconTheme: const IconThemeData(color: AppColors.secondaryText),
        ),
      );
      expect(_icons(tester), hasLength(1));
      expect(_painted(tester), [AppColors.secondaryText]);
    });

    testWidgets('size and opacity apply to both layers', (tester) async {
      await tester.pumpWidget(
        _host(
          const HeroIcon(HeroIcons.star),
          iconTheme: const IconThemeData(
            color: AppColors.primaryText,
            size: 30,
            opacity: 0.5,
          ),
        ),
      );
      final texts = tester.widgetList<RichText>(find.byType(RichText));
      expect(texts, hasLength(2));
      for (final text in texts) {
        expect(text.text.style!.fontSize, 30);
        expect(text.text.style!.color!.a, closeTo(0.5, 0.01));
      }
    });
  });

  testWidgets('the semantic label is read out once', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const HeroIcon(
          HeroIcons.gift,
          color: AppColors.primaryText,
          semanticLabel: 'Gift',
        ),
      ),
    );
    expect(_icons(tester), hasLength(2));
    expect(find.bySemanticsLabel('Gift'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('shadows go under the line glyph only', (tester) async {
    const glow = [Shadow(color: AppColors.white, blurRadius: 4)];
    await tester.pumpWidget(
      _host(
        const HeroIcon(
          HeroIcons.gift,
          color: AppColors.primaryText,
          shadows: glow,
        ),
      ),
    );
    final icons = _icons(tester);
    expect(icons.first.shadows, isNull, reason: 'accent layer');
    expect(icons.last.shadows, glow);
  });
}
