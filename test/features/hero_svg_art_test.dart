// BX-13: the drawn Hero SVGs on the screens that replace the Material glyphs
// and the copied reference-app rasters (docs/motion/asset_manifest.md).
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
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/domain/entities/address_label.dart';
import 'package:hero_mart/src/core/domain/entities/offer_reward_entity.dart';
import 'package:hero_mart/src/core/widgets/address_label_icon.dart';
import 'package:hero_mart/src/core/widgets/cart_basket_badge.dart';
import 'package:hero_mart/src/core/widgets/catalog_circle_add_button.dart';
import 'package:hero_mart/src/core/widgets/hero_svg_glyph.dart';
import 'package:hero_mart/src/core/widgets/offer_plate.dart';
import 'package:hero_mart/src/core/widgets/recipe_meta_line.dart';
import 'package:hero_mart/src/core/widgets/shelf_add_button.dart';
import 'package:hero_mart/src/core/widgets/state_art.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/delivery_code/delivery_code_tips_card.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_edit/center_marker.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/chat/assistant_tool_glyphs.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/mascot/assistant_mascot.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/mascot/assistant_mascot_mood.dart';
import 'package:hero_mart/src/features/assistant/presentation/widgets/mascot/assistant_prop_scene.dart';
import 'package:hero_mart/src/features/coupons/presentation/widgets/coupons_empty_view.dart';
import 'package:hero_mart/src/features/marketing/presentation/widgets/offer_reward_disc.dart';
import 'package:hero_mart/src/features/notifications/domain/entities/notification_entity.dart';
import 'package:hero_mart/src/features/notifications/presentation/widgets/notification_kind_icon.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/tracking/tracking_rate_thanks.dart';
import 'package:hero_mart/src/features/shop/presentation/widgets/browse/category_rail_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The drawn SVG of [asset] (under a [HeroSvgGlyph] or a bare [SvgPicture]).
Finder _svg(String asset) => find.byWidgetPredicate(
  (widget) =>
      widget is SvgPicture &&
      (widget.bytesLoader as SvgAssetLoader).assetName == asset,
);

SvgPicture _picture(WidgetTester tester, String asset) =>
    tester.widget<SvgPicture>(_svg(asset));

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
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );

  group('HeroSvgGlyph', () {
    testWidgets('mono takes the IconTheme colour and size; art is never '
        'tinted; a label is read out, none is decorative', (tester) async {
      await pump(
        tester,
        const IconTheme(
          data: IconThemeData(color: AppColors.primaryDark, size: 30),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HeroSvgGlyph.mono(HeroAssets.tabAccount),
              HeroSvgGlyph.art(HeroAssets.proCrown, semanticLabel: 'Pro'),
            ],
          ),
        ),
      );
      final mono = _picture(tester, HeroAssets.tabAccount);
      expect(
        mono.colorFilter,
        const ColorFilter.mode(AppColors.primaryDark, BlendMode.srcIn),
      );
      expect(mono.width, 30);
      expect(mono.excludeFromSemantics, isTrue);
      final art = _picture(tester, HeroAssets.proCrown);
      expect(art.colorFilter, isNull);
      expect(art.semanticsLabel, 'Pro');
      expect(art.excludeFromSemantics, isFalse);
    });
  });

  group('basket and add controls', () {
    testWidgets('the basket bar draws the Hero basket, full once it holds '
        'something — no raster', (tester) async {
      await pump(tester, const CartBasketBadge(count: 0));
      expect(_svg(HeroAssets.cartBasket), findsOneWidget);
      expect(_svg(HeroAssets.cartBasketFull), findsNothing);
      expect(find.byType(Image), findsNothing);

      await pump(tester, const CartBasketBadge(count: 3));
      await tester.pump(const Duration(seconds: 1));
      expect(_svg(HeroAssets.cartBasketFull), findsOneWidget);
      expect(_svg(HeroAssets.cartBasket), findsNothing);
    });

    testWidgets('"choose options" wears the three-jar glyph, "+" stays', (
      tester,
    ) async {
      await pump(
        tester,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShelfAddButton(label: 'Choose', options: true, onTap: () {}),
            CatalogCircleAddButton(label: 'Add', onTap: () {}),
            CatalogCircleAddButton(label: 'Pick', options: true, onTap: () {}),
          ],
        ),
      );
      expect(_svg(HeroAssets.productOptions), findsNWidgets(2));
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsNothing);
    });
  });

  group('tags, plates and glyph maps', () {
    testWidgets('address tags draw their Hero glyph, tinted', (tester) async {
      await pump(
        tester,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AddressLabelIcon(label: AddressLabel.home),
            AddressLabelIcon(label: AddressLabel.work),
            AddressLabelIcon(label: AddressLabel.gathering),
            AddressLabelIcon(label: AddressLabel.other),
          ],
        ),
      );
      for (final asset in [
        HeroAssets.addressLabelHome,
        HeroAssets.addressLabelOffice,
        HeroAssets.addressLabelGathering,
        HeroAssets.addressLabelOther,
      ]) {
        expect(_svg(asset), findsOneWidget, reason: asset);
        expect(_picture(tester, asset).colorFilter, isNotNull);
      }
    });

    testWidgets('notification kinds: plates for money, rewards, offers and '
        'Pro, the person for the account, font glyphs for the rest', (
      tester,
    ) async {
      await pump(
        tester,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NotificationKindIcon(kind: NotificationKind.wallet),
            NotificationKindIcon(kind: NotificationKind.subscription),
            NotificationKindIcon(kind: NotificationKind.offer),
            NotificationKindIcon(kind: NotificationKind.account),
            NotificationKindIcon(kind: NotificationKind.order),
          ],
        ),
      );
      expect(_svg(HeroAssets.checkoutWallet), findsOneWidget);
      expect(_picture(tester, HeroAssets.proCrown).colorFilter, isNull);
      expect(_svg(HeroAssets.offerPercent), findsOneWidget);
      expect(_picture(tester, HeroAssets.tabAccount).colorFilter, isNotNull);
      expect(find.byIcon(HeroIcons.orders), findsOneWidget);
    });

    testWidgets('offer cards: the kind\'s Hero plate, a plain tag for any '
        'other offer', (tester) async {
      expect(
        OfferPlate.assetFor(OfferRewardType.percentageDiscount),
        HeroAssets.offerPercent,
      );
      expect(OfferPlate.assetFor(OfferRewardType.other), isNull);
      await pump(
        tester,
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OfferRewardDisc(type: OfferRewardType.percentageDiscount),
            OfferRewardDisc(type: OfferRewardType.freeDelivery),
            OfferRewardDisc(type: OfferRewardType.other),
          ],
        ),
      );
      expect(_svg(HeroAssets.offerPercent), findsOneWidget);
      expect(_svg(HeroAssets.offerDelivery), findsOneWidget);
      expect(find.byIcon(Icons.local_offer_outlined), findsOneWidget);
      expect(find.byIcon(Icons.percent_rounded), findsNothing);
    });

    test('assistant steps map to the Hero set; the van mirrors itself', () {
      expect(AssistantToolGlyphs.of(null).asset, HeroAssets.assistantAi);
      expect(
        AssistantToolGlyphs.of('search_recipes').asset,
        HeroAssets.recipePot,
      );
      expect(
        AssistantToolGlyphs.of('check_delivery').asset,
        HeroAssets.sharedClock,
      );
      expect(
        AssistantToolGlyphs.of('list_offers').asset,
        HeroAssets.checkoutCodeTag,
      );
      final van = AssistantToolGlyphs.of('track_order').icon!;
      expect(van, HeroIcons.deliveryDirectional);
      expect(van.matchTextDirection, isTrue);
      expect(AssistantToolGlyphs.of('unknown'), AssistantToolGlyphs.thinking);
    });
  });

  group('screens', () {
    testWidgets('the "All" rail entry wears its own glyph, not a picture', (
      tester,
    ) async {
      await pump(
        tester,
        CategoryRailItem(
          label: 'All',
          image: '',
          selected: true,
          all: true,
          onTap: () {},
        ),
      );
      expect(_svg(HeroAssets.categoryAll), findsOneWidget);
      expect(find.byIcon(Icons.category_outlined), findsNothing);
    });

    testWidgets('recipe meta: the Hero clock and person beside the words', (
      tester,
    ) async {
      await pump(tester, const RecipeMetaLine(minutes: 80, servings: 6));
      expect(find.text('80 min'), findsOneWidget);
      expect(find.text('6 servings'), findsOneWidget);
      expect(_svg(HeroAssets.sharedClock), findsOneWidget);
      expect(_svg(HeroAssets.tabAccount), findsOneWidget);
    });

    testWidgets('the address map pin is the drawn Hero pin, decorative', (
      tester,
    ) async {
      await pump(tester, const CenterMarker(raised: false, label: 'Home'));
      final pin = _picture(tester, HeroAssets.mapPin);
      expect(pin.width, 40);
      expect(pin.height, 48);
      expect(pin.excludeFromSemantics, isTrue);
    });

    testWidgets('delivery code: the handover picture mirrors in RTL', (
      tester,
    ) async {
      await pump(
        tester,
        const SingleChildScrollView(child: DeliveryCodeTipsCard()),
        direction: TextDirection.rtl,
      );
      final art = _picture(tester, HeroAssets.deliveryCodeHandover);
      expect(art.matchTextDirection, isTrue);
      expect(art.excludeFromSemantics, isTrue);
    });

    testWidgets(
      'assistant props: a directional prop points at the mascot in RTL — '
      'prop and mascot both mirror; a plain prop does not',
      (tester) async {
        await pump(
          tester,
          const AssistantPropScene(
            prop: HeroAssets.assistantPropHandoff,
            mood: AssistantMascotMood.handingOver,
            directional: true,
          ),
          direction: TextDirection.rtl,
        );
        expect(
          _picture(tester, HeroAssets.assistantPropHandoff).matchTextDirection,
          isTrue,
        );
        final flip = tester.widget<Transform>(
          find
              .ancestor(
                of: find.byType(AssistantMascot),
                matching: find.byType(Transform),
              )
              .first,
        );
        expect(flip.transform.entry(0, 0), -1);

        await pump(
          tester,
          const AssistantPropScene(prop: HeroAssets.assistantPropMic),
          direction: TextDirection.rtl,
        );
        expect(
          _picture(tester, HeroAssets.assistantPropMic).matchTextDirection,
          isFalse,
        );
      },
    );

    testWidgets('coupon tabs share the "no offers" art', (tester) async {
      await pump(
        tester,
        const SizedBox(
          height: 600,
          child: CouponsEmptyView(message: 'No coupons yet'),
        ),
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is StateArt && widget.asset == HeroAssets.emptyCoupons,
        ),
        findsOneWidget,
      );
      expect(find.text('No coupons yet'), findsOneWidget);
    });

    testWidgets('a sent rating shows the Hero "done" sticker at card size', (
      tester,
    ) async {
      await pump(tester, const TrackingRateThanks());
      await tester.pumpAndSettle();
      final sticker = _picture(tester, HeroAssets.stateSuccess);
      expect(sticker.width, StateArt.compactWidth);
      expect(sticker.height, StateArt.compactHeight);
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });
  });
}
