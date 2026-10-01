// The sticker icon rollout on real surfaces: the bottom bar (selected tab =
// ink line over its natural fill, idle tab = one grey glyph), a former solid
// `*Fill` "selected" glyph now drawn as the outline sticker, and the feature
// tiles that moved onto HeroIconPlate.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/config/theme/app_theme.dart';
import 'package:hero_mart/src/core/design/hero_icon_fill_colors.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/widgets/hero_icon.dart';
import 'package:hero_mart/src/core/widgets/hero_icon_plate.dart';
import 'package:hero_mart/src/features/account/domain/entities/loyalty_entry_entity.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/loyalty/loyalty_entry_label.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/mine/mine_icon_tile.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/mine/mine_tone.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/settings/settings_icon_badge.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/settings/settings_tone.dart';
import 'package:hero_mart/src/features/checkout/presentation/widgets/checkout/checkout_payment_icon.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/review/review_star_icon.dart';
import 'package:hero_mart/src/features/shell/presentation/widgets/shell_nav_item.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

/// The colours the glyphs under [of] are painted in, bottom layer first.
List<Color?> _painted(WidgetTester tester, Finder of) => tester
    .widgetList<RichText>(
      find.descendant(of: of, matching: find.byType(RichText)),
    )
    .where((text) => text.text.style?.fontFamily == HeroIcons.fontFamily)
    .map((text) => text.text.style?.color)
    .toList();

List<Icon> _layers(WidgetTester tester, Finder of) => tester
    .widgetList<Icon>(find.descendant(of: of, matching: find.byType(Icon)))
    .toList();

Color _tile(WidgetTester tester, Finder of) =>
    (tester
                .widget<DecoratedBox>(
                  find.descendant(of: of, matching: find.byType(DecoratedBox)),
                )
                .decoration
            as BoxDecoration)
        .color!;

void main() {
  group('bottom bar', () {
    Widget tab(IconData icon, {required bool selected}) => _host(
      SizedBox(
        width: 90,
        height: 56,
        child: ShellNavItem(
          icon: HeroIcon(icon),
          label: 'Tab',
          selected: selected,
          onTap: () {},
        ),
      ),
    );

    for (final icon in [HeroIcons.search, HeroIcons.cart, HeroIcons.account]) {
      testWidgets('the selected tab is the sticker ($icon)', (tester) async {
        await tester.pumpWidget(tab(icon, selected: true));
        await tester.pumpAndSettle();
        final item = find.byType(ShellNavItem);
        final layers = _layers(tester, item);
        expect(layers, hasLength(2), reason: 'accent + line');
        expect(layers.first.icon, HeroIcons.accentOf(icon));
        expect(layers.last.icon, icon);
        expect(_painted(tester, item), [
          HeroIcons.fillOf(icon)!.color,
          HeroColors.light.iconInk,
        ]);
      });

      testWidgets('an idle tab is one grey glyph ($icon)', (tester) async {
        await tester.pumpWidget(tab(icon, selected: false));
        await tester.pumpAndSettle();
        final item = find.byType(ShellNavItem);
        expect(_layers(tester, item).single.icon, icon);
        expect(_painted(tester, item), [AppColors.tertiaryText]);
      });
    }
  });

  group('Fill → outline sticker', () {
    testWidgets('a filled review star is the ink + amber sticker, not a blob', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const ReviewStarIcon(filled: true)));
      await tester.pumpAndSettle();
      final star = find.byType(ReviewStarIcon);
      expect(find.byIcon(HeroIcons.starFill), findsNothing);
      expect(_painted(tester, star), [
        AppColors.secondaryText, // the grey outline under it
        HeroIconFill.amber.color,
        HeroColors.light.iconInk,
      ]);
    });

    test('an unknown loyalty entry takes the outline points glyph', () {
      expect(
        LoyaltyEntryLabel.iconOf(LoyaltyEntryKind.other),
        HeroIcons.points,
      );
    });
  });

  group('feature tiles on plates', () {
    testWidgets('a Mine menu row: white glyph on its tone plate', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const MineIconTile(icon: HeroIcons.orders, tone: MineTone.brand)),
      );
      final plate = find.byType(HeroIconPlate);
      expect(plate, findsOneWidget);
      expect(_tile(tester, plate), AppColors.primaryDark);
      expect(_painted(tester, plate), [AppColors.white]);
      expect(tester.getSize(plate), const Size.square(MineIconTile.size));
    });

    testWidgets('a neutral Mine row takes the icon\'s own fill family', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MineIconTile(icon: HeroIcons.settings, tone: MineTone.neutral),
        ),
      );
      expect(
        _tile(tester, find.byType(HeroIconPlate)),
        HeroIconPlate.plateColorOf(HeroIcons.settings),
      );
    });

    testWidgets('a Mine quick stat keeps its soft disc with a sticker glyph', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const MineIconTile(
            icon: HeroIcons.points,
            tone: MineTone.amber,
            circle: true,
          ),
        ),
      );
      final tile = find.byType(MineIconTile);
      expect(find.byType(HeroIconPlate), findsNothing);
      expect(_painted(tester, tile), [
        HeroIconFill.amber.color,
        HeroColors.light.iconInk,
      ]);
    });

    testWidgets('a settings badge keeps its tone: logout on red', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SettingsIconBadge(
            icon: HeroIcons.logout,
            tone: SettingsTone.danger,
          ),
        ),
      );
      final plate = find.byType(HeroIconPlate);
      expect(_tile(tester, plate), AppColors.logoutRed);
      expect(_painted(tester, plate), [AppColors.white]);
      expect(
        tester.getSize(plate),
        const Size.square(SettingsIconBadge.defaultDimension),
      );
    });

    testWidgets('the cash payment row: white note on the brand plate', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const CheckoutPaymentIcon(icon: HeroIcons.cash)),
      );
      final plate = find.byType(HeroIconPlate);
      expect(_tile(tester, plate), HeroIconPlate.plateColorOf(HeroIcons.cash));
      expect(_painted(tester, plate), [AppColors.white]);
      expect(
        tester.getSize(plate),
        const Size.square(CheckoutPaymentIcon.size),
      );
    });

    test('every tone plate carries a white glyph at 3:1 or more', () {
      double contrast(Color plate) => 1.05 / (plate.computeLuminance() + 0.05);
      final plates = <String, Color?>{
        for (final tone in MineTone.values) 'mine.${tone.name}': tone.plate,
        for (final tone in SettingsTone.values)
          'settings.${tone.name}': tone.plate,
      };
      for (final MapEntry(key: name, value: plate) in plates.entries) {
        if (plate == null) continue;
        expect(contrast(plate), greaterThanOrEqualTo(3), reason: name);
      }
    });
  });
}
