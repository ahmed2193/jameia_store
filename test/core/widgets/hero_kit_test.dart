// The Hero* kit the search and cart / checkout / orders screens are built
// from: money reads left-to-right with the localized label, links announce
// themselves, the signed-out state signs in with `go`, choice rows are
// checkable, list cards put hairlines only between rows and the title bar
// never offers a back button on a root route.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show Intl;
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/config/theme/app_text_styles.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/motion/press_scale.dart';
import 'package:hero_mart/src/core/responsive/app_size.dart';
import 'package:hero_mart/src/core/utils/formatters.dart';
import 'package:hero_mart/src/core/widgets/app_button.dart';
import 'package:hero_mart/src/core/widgets/hero_icon.dart';
import 'package:hero_mart/src/core/widgets/hero_image.dart';
import 'package:hero_mart/src/core/widgets/hero_input_decoration.dart';
import 'package:hero_mart/src/core/widgets/hero_line_thumb.dart';
import 'package:hero_mart/src/core/widgets/hero_list_card.dart';
import 'package:hero_mart/src/core/widgets/hero_list_row.dart';
import 'package:hero_mart/src/core/widgets/hero_money_text.dart';
import 'package:hero_mart/src/core/widgets/hero_segment.dart';
import 'package:hero_mart/src/core/widgets/hero_segmented_control.dart';
import 'package:hero_mart/src/core/widgets/hero_state_view.dart';
import 'package:hero_mart/src/core/widgets/hero_submit_button.dart';
import 'package:hero_mart/src/core/widgets/hero_text_link.dart';
import 'package:hero_mart/src/core/widgets/hero_title_bar.dart';
import 'package:hero_mart/src/core/widgets/option_row.dart';
import 'package:hero_mart/src/core/widgets/ready_wipe.dart';
import 'package:hero_mart/src/core/widgets/round_back_button.dart';
import 'package:hero_mart/src/core/widgets/segmented_thumb_track.dart';
import 'package:hero_mart/src/core/widgets/sticker_text.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  tearDown(() => Intl.defaultLocale = null);

  group('money', () {
    test('priceLtr leads with the label in both languages', () {
      Intl.defaultLocale = 'en';
      expect(Formatters.priceLtr(1.25), 'KD 1.250');
      Intl.defaultLocale = 'ar';
      expect(Formatters.priceLtr(1.25), 'د.ك 1.250');
      expect(Formatters.price(1.25), '1.250 د.ك');
    });

    testWidgets('HeroMoneyText is one LTR run read as the price', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      Intl.defaultLocale = 'ar';
      await tester.pumpWidget(
        _host(
          const Directionality(
            textDirection: TextDirection.rtl,
            child: HeroMoneyText(kd: 0.5, negative: true),
          ),
        ),
      );

      final text = find.text('- د.ك 0.500');
      expect(text, findsOneWidget);
      final direction = tester.widget<Directionality>(
        find.ancestor(of: text, matching: find.byType(Directionality)).first,
      );
      expect(direction.textDirection, TextDirection.ltr);
      expect(find.bySemanticsLabel('- 0.500 د.ك'), findsOneWidget);
      semantics.dispose();
    });
  });

  group('HeroTextLink', () {
    testWidgets('announces a link, or a button for an in-page action', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              HeroTextLink(label: 'View all', onTap: () {}),
              HeroTextLink(label: 'Clear', navigates: false, onTap: () {}),
            ],
          ),
        ),
      );
      expect(
        tester.getSemantics(find.byType(HeroTextLink).first),
        isSemantics(label: 'View all', isLink: true, isEnabled: true),
      );
      expect(
        tester.getSemantics(find.byType(HeroTextLink).last),
        isSemantics(label: 'Clear', isButton: true, isLink: false),
      );
      semantics.dispose();
    });

    testWidgets('without onTap it is disabled', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(const HeroTextLink(label: 'Clear cart', onTap: null)),
      );
      expect(
        tester.getSemantics(find.byType(HeroTextLink)),
        isSemantics(label: 'Clear cart', isEnabled: false),
      );
      semantics.dispose();
    });
  });

  testWidgets('signed-out state goes to sign-in', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: HeroStateView.signedOut(message: 'Sign in to see orders'),
          ),
        ),
        GoRoute(
          path: Routes.login,
          builder: (_, _) => const Scaffold(body: Text('login page')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.text('Sign in to see orders'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    expect(find.text('login page'), findsOneWidget);
  });

  group('OptionRow', () {
    testWidgets('is a checkable member of its group', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(OptionRow(title: 'Cash', selected: true, onTap: () {})),
      );
      expect(
        tester.getSemantics(find.byType(OptionRow)),
        isSemantics(
          label: 'Cash',
          hasCheckedState: true,
          isChecked: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('a disabled row ignores taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          OptionRow(
            title: 'Wallet',
            selected: false,
            enabled: false,
            onTap: () => taps++,
          ),
        ),
      );
      await tester.tap(find.text('Wallet'));
      expect(taps, 0);
    });

    testWidgets('a leading widget takes the icon slot', (tester) async {
      const plate = SizedBox.square(key: ValueKey('plate'), dimension: 22);
      await tester.pumpWidget(
        _host(
          OptionRow(
            title: 'Cash',
            selected: false,
            icon: Icons.payments_outlined,
            leading: plate,
            onTap: () {},
          ),
        ),
      );
      expect(find.byKey(const ValueKey('plate')), findsOneWidget);
      expect(find.byIcon(Icons.payments_outlined), findsNothing);
      // The text keeps the icon's 16 dp gap after the art.
      expect(
        tester.getTopLeft(find.text('Cash')).dx -
            tester.getTopRight(find.byKey(const ValueKey('plate'))).dx,
        16,
      );
    });
  });

  testWidgets('HeroListCard puts a hairline between rows only', (tester) async {
    await tester.pumpWidget(
      _host(
        const HeroListCard(children: [Text('one'), Text('two'), Text('three')]),
      ),
    );
    expect(find.byType(Divider), findsNWidgets(2));
  });

  testWidgets('title bar offers back only when there is somewhere to go', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) =>
              const Scaffold(appBar: HeroTitleBar(title: 'Root')),
        ),
        GoRoute(
          path: '/next',
          builder: (_, _) =>
              const Scaffold(appBar: HeroTitleBar(title: 'Next')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.byType(RoundBackButton), findsNothing);

    router.push('/next');
    await tester.pumpAndSettle();
    expect(find.text('Next'), findsOneWidget);
    expect(find.byType(RoundBackButton), findsOneWidget);
  });

  testWidgets('HeroTitleBar shows an optional subtitle', (tester) async {
    Future<void> pump(String? subtitle) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: HeroTitleBar(title: 'Checkout', subtitle: subtitle),
        ),
      ),
    );

    await pump('Hero · Salmiya');
    final title = tester.getRect(find.text('Checkout'));
    final subtitle = tester.getRect(find.text('Hero · Salmiya'));
    final bar = tester.getRect(find.byType(HeroTitleBar));
    expect(subtitle.top, greaterThanOrEqualTo(title.bottom));
    expect(title.left, subtitle.left);
    expect(bar.height, HeroTitleBar.height);
    expect(subtitle.bottom, lessThanOrEqualTo(bar.bottom));

    // The line folds away (it keeps drawing while it closes).
    await pump('');
    await tester.pumpAndSettle();
    expect(find.text('Checkout'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HeroTitleBar),
        matching: find.byType(Text),
      ),
      findsOneWidget,
    );
  });

  group('HeroListRow', () {
    Future<void> pump(
      WidgetTester tester,
      Widget row, {
      TextDirection direction = TextDirection.ltr,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Scaffold(body: Column(children: [row])),
        ),
      ),
    );

    Finder hairline() => find.byWidgetPredicate(
      (widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).border != null,
    );

    HeroListRow row({bool dense = false, bool divider = false}) => HeroListRow(
      icon: HeroIcons.pin,
      title: 'Select a delivery address',
      dense: dense,
      divider: divider,
      onTap: () {},
    );

    testWidgets('keeps its 56 dp, 24 dp icon look by default', (tester) async {
      await pump(tester, row());

      expect(tester.getSize(find.byType(HeroListRow)).height, AppSize.s56);
      expect(
        tester.getSize(find.byIcon(HeroIcons.pin)),
        const Size.square(AppSize.s24),
      );
      expect(hairline(), findsNothing);
    });

    testWidgets('dense is 52 dp with a 20 dp leading and draws the divider '
        'from the text start', (tester) async {
      await pump(tester, row(dense: true, divider: true));

      final rowRect = tester.getRect(find.byType(HeroListRow));
      expect(rowRect.height, HeroListRow.denseMinHeight);
      expect(
        tester.getSize(find.byIcon(HeroIcons.pin)),
        const Size.square(AppSize.s20),
      );
      final text = tester.getRect(find.text('Select a delivery address'));
      final line = tester.getRect(hairline());
      expect(text.left, HeroListRow.denseTextStart);
      expect(line.left, text.left);
      expect(line.right, rowRect.right);
      expect(line.bottom, rowRect.bottom);
    });

    testWidgets('the divider mirrors in RTL', (tester) async {
      await pump(
        tester,
        row(dense: true, divider: true),
        direction: TextDirection.rtl,
      );

      final rowRect = tester.getRect(find.byType(HeroListRow));
      final line = tester.getRect(hairline());
      expect(line.left, rowRect.left);
      expect(line.right, rowRect.right - HeroListRow.denseTextStart);
    });

    testWidgets('dense without divider draws no hairline', (tester) async {
      await pump(tester, row(dense: true));
      expect(hairline(), findsNothing);
    });
  });

  testWidgets('HeroLineThumb decodes at its size', (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeroLineThumb(url: ''),
            HeroLineThumb(url: '', size: AppSize.s40),
          ],
        ),
      ),
    );

    final images = tester
        .widgetList<HeroImage>(find.byType(HeroImage))
        .toList();
    expect(images, hasLength(2));
    expect(images.first.width, AppSize.s56);
    expect(images.first.height, AppSize.s56);
    expect(images.last.width, AppSize.s40);
    expect(images.last.height, AppSize.s40);
    expect(
      tester.getSize(find.byType(HeroLineThumb).first),
      const Size.square(AppSize.s56),
    );
  });
  group('HeroSubmitButton', () {
    Future<void> pump(
      WidgetTester tester, {
      bool enabled = true,
      bool holding = false,
      bool readyFlourish = false,
      VoidCallback? onPressed,
      VoidCallback? onBlocked,
    }) => tester.pumpWidget(
      _host(
        SizedBox(
          width: 240,
          child: HeroSubmitButton(
            label: 'Place order',
            sticker: true,
            enabled: enabled,
            holding: holding,
            readyFlourish: readyFlourish,
            onPressed: onPressed ?? () {},
            onBlocked: onBlocked,
          ),
        ),
      ),
    );

    Color? fill(WidgetTester tester) {
      final box = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(HeroSubmitButton),
          matching: find.byType(AnimatedContainer),
        ),
      );
      return (box.decoration as BoxDecoration?)?.color;
    }

    /// The label states the fade-through holds (two while it cross-fades).
    Finder labelStates() => find.byWidgetPredicate(
      (widget) =>
          widget is KeyedSubtree &&
          widget.key is ValueKey<Object> &&
          (widget.key! as ValueKey<Object>).value is (Object, bool),
    );

    testWidgets('holding keeps the green sticker look but takes no tap', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      var taps = 0;
      var blocked = 0;
      await pump(
        tester,
        enabled: false,
        holding: true,
        onPressed: () => taps++,
        onBlocked: () => blocked++,
      );

      expect(fill(tester), AppColors.primary);
      expect(
        find.descendant(
          of: find.byType(StickerText),
          matching: find.text('Place order'),
        ),
        findsWidgets,
      );
      expect(tester.widget<PressScale>(find.byType(PressScale)).enabled, false);

      await tester.tap(find.byType(HeroSubmitButton));
      await tester.pumpAndSettle();
      expect(taps, 0);
      expect(blocked, 0);
      expect(
        tester.getSemantics(find.byType(HeroSubmitButton)),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
      semantics.dispose();
    });

    testWidgets('a disabled pill still reports a blocked tap', (tester) async {
      var blocked = 0;
      await pump(tester, enabled: false, onBlocked: () => blocked++);

      expect(fill(tester), AppColors.divider);
      await tester.tap(find.byType(HeroSubmitButton));
      expect(blocked, 1);
    });

    testWidgets('the ready flourish is off by default', (tester) async {
      await pump(tester);
      expect(find.byType(ReadyWipe), findsNothing);
      expect(fill(tester), AppColors.primary);
    });

    testWidgets('with the flourish, turning green wipes and cross-fades the '
        'label once; a holding cycle never replays it', (tester) async {
      await pump(tester, enabled: false, readyFlourish: true);
      expect(find.byType(ReadyWipe), findsOneWidget);
      expect(tester.widget<ReadyWipe>(find.byType(ReadyWipe)).ready, isFalse);
      expect(labelStates(), findsOneWidget);

      await pump(tester, readyFlourish: true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.widget<ReadyWipe>(find.byType(ReadyWipe)).ready, isTrue);
      expect(labelStates(), findsNWidgets(2));
      await tester.pumpAndSettle();
      expect(labelStates(), findsOneWidget);

      // A re-price: enabled → holding → enabled stays green, no replay.
      for (final holding in [true, false, true, false]) {
        await pump(
          tester,
          enabled: !holding,
          holding: holding,
          readyFlourish: true,
        );
        await tester.pump();
        expect(labelStates(), findsOneWidget);
        expect(tester.hasRunningAnimations, isFalse);
      }
    });
  });

  group('HeroSegmentedControl', () {
    Future<void> pump(
      WidgetTester tester, {
      HeroSegmentTone tone = HeroSegmentTone.dark,
      IconData? Function(String)? iconOf,
    }) => tester.pumpWidget(
      _host(
        SizedBox(
          width: 320,
          child: HeroSegmentedControl<String>(
            values: const ['Delivery', 'Pickup'],
            selected: 'Delivery',
            labelOf: (value) => value,
            onChanged: (_) {},
            tone: tone,
            iconOf: iconOf,
          ),
        ),
      ),
    );

    BoxDecoration thumb(WidgetTester tester) =>
        tester
                .widget<DecoratedBox>(
                  // The thumb is the track's first box (drawn under the
                  // segments).
                  find
                      .descendant(
                        of: find.byType(SegmentedThumbTrack),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;

    TextStyle labelStyle(WidgetTester tester, String label) => tester
        .widget<AnimatedDefaultTextStyle>(
          find
              .ancestor(
                of: find.text(label),
                matching: find.byType(AnimatedDefaultTextStyle),
              )
              .first,
        )
        .style;

    testWidgets('the default dark thumb is unchanged', (tester) async {
      await pump(tester);
      expect(thumb(tester).color, AppColors.primaryText);
      expect(thumb(tester).border, isNull);
      expect(labelStyle(tester, 'Delivery').color, AppColors.white);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('brandSoft: a mint thumb with a green hairline, the chosen '
        'label deep green and bold, icons coloured by choice', (tester) async {
      await pump(
        tester,
        tone: HeroSegmentTone.brandSoft,
        iconOf: (value) =>
            value == 'Pickup' ? HeroIcons.store : HeroIcons.delivery,
      );
      await tester.pumpAndSettle();

      final decoration = thumb(tester);
      expect(decoration.color, AppColors.brandWash);
      expect((decoration.border! as Border).top.color, AppColors.primary);
      expect((decoration.border! as Border).top.width, AppSize.s1);
      expect(labelStyle(tester, 'Delivery').color, AppColors.brandDeep);
      expect(labelStyle(tester, 'Delivery').fontWeight, AppTextStyles.bold);
      expect(labelStyle(tester, 'Pickup').color, AppColors.primaryText);
      expect(
        tester
            .widget<HeroIcon>(find.widgetWithIcon(HeroIcon, HeroIcons.delivery))
            .color,
        AppColors.primary,
      );
      expect(
        tester
            .widget<HeroIcon>(find.widgetWithIcon(HeroIcon, HeroIcons.store))
            .color,
        AppColors.primaryText,
      );
      // Both colours read as ink: each glyph is the sticker, its line in
      // iconInk.
      for (final icon in [HeroIcons.delivery, HeroIcons.store]) {
        expect(
          tester.widget<Icon>(find.byIcon(icon)).color,
          HeroColors.light.iconInk,
        );
      }
      expect(
        tester.getSize(find.byIcon(HeroIcons.store)),
        const Size.square(HeroSegment.iconSize),
      );
    });
  });

  group('OptionRow looks', () {
    Future<void> pump(
      WidgetTester tester,
      Widget row, {
      TextDirection direction = TextDirection.ltr,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: Scaffold(body: Column(children: [row])),
        ),
      ),
    );

    OptionRow row({
      OptionRowLook look = OptionRowLook.plain,
      bool selected = false,
      bool enabled = true,
    }) => OptionRow(
      title: 'As soon as possible',
      subtitle: 'About 40 min',
      icon: HeroIcons.clock,
      iconColor: AppColors.primary,
      selected: selected,
      enabled: enabled,
      look: look,
      onTap: () {},
    );

    BoxDecoration card(WidgetTester tester) =>
        tester
                .widget<AnimatedContainer>(
                  find
                      .descendant(
                        of: find.byType(OptionRow),
                        matching: find.byType(AnimatedContainer),
                      )
                      .first,
                )
                .decoration!
            as BoxDecoration;

    Finder dimming() => find.descendant(
      of: find.byType(OptionRow),
      matching: find.byType(Opacity),
    );

    testWidgets('plain keeps its 16 dp gutter, 24 dp icon and dimming', (
      tester,
    ) async {
      await pump(tester, row(enabled: false));
      expect(tester.getTopLeft(find.byIcon(HeroIcons.clock)).dx, 16);
      expect(
        tester.getSize(find.byIcon(HeroIcons.clock)),
        const Size.square(AppSize.s24),
      );
      expect(tester.getTopLeft(find.text('As soon as possible')).dx, 56);
      expect(dimming(), findsOneWidget);
    });

    testWidgets('dense: the icon at 12 dp and the text at the dense text '
        'column, in both directions', (tester) async {
      await pump(tester, row(look: OptionRowLook.dense));
      expect(tester.getTopLeft(find.byIcon(HeroIcons.clock)).dx, 12);
      expect(
        tester.getTopLeft(find.text('As soon as possible')).dx,
        HeroListRow.denseTextStart,
      );
      expect(
        tester
            .widget<HeroIcon>(find.widgetWithIcon(HeroIcon, HeroIcons.clock))
            .color,
        AppColors.primary,
      );
      // Brand green reads as ink: the clock is the sticker.
      expect(
        tester.widget<Icon>(find.byIcon(HeroIcons.clock)).color,
        HeroColors.light.iconInk,
      );
      final sub = tester.widget<Text>(find.text('About 40 min'));
      expect(sub.style!.color, AppColors.labelGrey);
      expect(sub.style!.fontSize, AppTextStyles.bodySmall.fontSize);

      await pump(
        tester,
        row(look: OptionRowLook.dense),
        direction: TextDirection.rtl,
      );
      final width = tester.getSize(find.byType(OptionRow)).width;
      expect(tester.getTopRight(find.byIcon(HeroIcons.clock)).dx, width - 12);
      expect(
        tester.getTopRight(find.text('As soon as possible')).dx,
        width - HeroListRow.denseTextStart,
      );
    });

    testWidgets('card: mint with a green hairline once chosen, white with a '
        'grey one otherwise', (tester) async {
      await pump(tester, row(look: OptionRowLook.card, selected: true));
      await tester.pumpAndSettle();
      expect(card(tester).color, AppColors.brandWash);
      expect((card(tester).border! as Border).top.color, AppColors.primary);
      expect(
        tester.widget<Text>(find.text('As soon as possible')).style!.fontWeight,
        AppTextStyles.itemTitleStrong.fontWeight,
      );

      await pump(tester, row(look: OptionRowLook.card));
      await tester.pumpAndSettle();
      expect(card(tester).color, AppColors.white);
      expect((card(tester).border! as Border).top.color, AppColors.divider);
    });

    testWidgets('disabled dense and card rows use the disabled colours, '
        'with no dimming layer', (tester) async {
      for (final look in [OptionRowLook.dense, OptionRowLook.card]) {
        await pump(tester, row(look: look, enabled: false));
        expect(dimming(), findsNothing);
        expect(
          tester.widget<Text>(find.text('As soon as possible')).style!.color,
          AppColors.tertiaryText,
        );
        expect(
          tester.widget<Icon>(find.byIcon(HeroIcons.clock)).color,
          AppColors.disabledText,
        );
      }
    });

    testWidgets('dense and card stay checkable members of their group', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      for (final look in [OptionRowLook.dense, OptionRowLook.card]) {
        await pump(tester, row(look: look, selected: true));
        expect(
          tester.getSemantics(find.byType(OptionRow)),
          isSemantics(
            hasCheckedState: true,
            isChecked: true,
            isInMutuallyExclusiveGroup: true,
          ),
        );
      }
      semantics.dispose();
    });
  });

  group('HeroListRow dense defaults', () {
    Future<void> pump(WidgetTester tester, {required bool dense}) =>
        tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  HeroListRow(
                    icon: Icons.sticky_note_2_outlined,
                    title: 'Note',
                    subtitle: 'Ring the bell',
                    dense: dense,
                    titleStyle: AppTextStyles.itemTitleStrong,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        );

    testWidgets('dense: a 16 dp grey chevron and a 12 sp grey sub-line', (
      tester,
    ) async {
      await pump(tester, dense: true);
      final chevron = tester.widget<Icon>(find.byIcon(HeroIcons.chevronEnd));
      expect(chevron.size, AppSize.s16);
      expect(chevron.color, AppColors.secondaryText);
      final sub = tester.widget<Text>(find.text('Ring the bell'));
      expect(sub.style!.fontSize, AppTextStyles.bodySmall.fontSize);
      expect(sub.style!.color, AppColors.labelGrey);
      final title = tester.widget<Text>(find.text('Note'));
      expect(title.style!.fontWeight, AppTextStyles.itemTitleStrong.fontWeight);
      expect(title.style!.color, AppColors.primaryText);
    });

    testWidgets('non-dense is unchanged', (tester) async {
      await pump(tester, dense: false);
      final chevron = tester.widget<Icon>(find.byIcon(HeroIcons.chevronEnd));
      expect(chevron.size, AppSize.s24);
      expect(chevron.color, AppColors.tertiaryText);
      final sub = tester.widget<Text>(find.text('Ring the bell'));
      expect(sub.style!.fontSize, AppTextStyles.meta.fontSize);
      expect(sub.style!.color, AppColors.secondaryText);
    });
  });

  test('HeroInputDecoration.outlined(error:) draws a red resting outline', () {
    OutlineInputBorder border(InputBorder? value) =>
        value! as OutlineInputBorder;

    final idle = HeroInputDecoration.outlined(hintText: 'Code');
    expect(border(idle.enabledBorder).borderSide.color, AppColors.divider);

    final refused = HeroInputDecoration.outlined(hintText: 'Code', error: true);
    expect(border(refused.enabledBorder).borderSide.color, AppColors.error);
    expect(border(refused.border).borderSide.color, AppColors.error);
    expect(
      border(refused.focusedBorder).borderSide.color,
      border(idle.focusedBorder).borderSide.color,
    );
  });
}
