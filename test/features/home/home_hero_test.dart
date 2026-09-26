// The home header as the storefront header: the store row (badge, "pro" tag,
// name, delivery-time pill) and the delivery line above the search pill, and
// the search pill stays in the bar once the feed has scrolled.
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_assistant_button.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_eta_pill.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_hero_deliver_to.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_hero_delegate.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_hero_search_field.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_notifications_bell.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_pro_badge.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_store_identity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The largest text the app lets through (`TextScalerClamp`).
const TextScaler _largestText = TextScaler.linear(1.3);

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

  late int searches;
  late int addressTaps;
  late int assistantTaps;

  Future<void> pumpHero(
    WidgetTester tester, {
    int etaMinutes = 40,
    bool isPro = true,
    TextScaler textScaler = TextScaler.noScaling,
    bool withAssistant = false,
  }) {
    searches = 0;
    addressTaps = 0;
    assistantTaps = 0;
    return tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: MaterialApp(
          home: Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: HomeHeroDelegate(
                    storeName: 'Jm3eia',
                    isPro: isPro,
                    etaMinutes: etaMinutes,
                    placeLabel: 'Apartment',
                    topPad: 0,
                    textScaler: textScaler,
                    onAddressTap: () => addressTaps++,
                    onSearch: () => searches++,
                    onNotifications: () {},
                    hasUnreadNotifications: false,
                    onAssistant: withAssistant ? () => assistantTaps++ : null,
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 2000)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double opacityOf(WidgetTester tester, Type part) => tester
      .widget<Opacity>(
        find
            .ancestor(of: find.byType(part), matching: find.byType(Opacity))
            .first,
      )
      .opacity;

  testWidgets('open: the store row over the delivery line and search pill', (
    tester,
  ) async {
    await pumpHero(tester);

    expect(find.text('Jm3eia'), findsOneWidget);
    expect(find.byType(HomeProBadge), findsOneWidget);
    expect(find.text('Delivering in 40 mins'), findsOneWidget);
    expect(opacityOf(tester, HomeStoreIdentity), 1.0);
    expect(opacityOf(tester, HomeHeroDeliverTo), 1.0);
    expect(
      find.textContaining('Apartment', findRichText: true),
      findsOneWidget,
    );

    await tester.tap(find.byType(HomeHeroDeliverTo));
    expect(addressTaps, 1);
    await tester.tap(find.byType(HomeHeroSearchField));
    expect(searches, 1);
  });

  testWidgets('no ETA yet: no pill, and nothing below it moves', (
    tester,
  ) async {
    await pumpHero(tester);
    final searchWithEta = tester.getTopLeft(find.byType(HomeHeroSearchField));

    await pumpHero(tester, etaMinutes: 0, isPro: false);

    expect(find.byType(HomeEtaPill), findsNothing);
    expect(find.byType(HomeProBadge), findsNothing);
    expect(find.text('Jm3eia'), findsOneWidget);
    // The header reserves the pill's line either way, so the feed does not
    // jump when the launch snapshot lands.
    expect(tester.getTopLeft(find.byType(HomeHeroSearchField)), searchWithEta);
  });

  testWidgets('collapsed: the store row and delivery line go, search stays', (
    tester,
  ) async {
    await pumpHero(tester);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(opacityOf(tester, HomeHeroDeliverTo), 0.0);
    expect(opacityOf(tester, HomeStoreIdentity), 0.0);
    // Still there, pinned in the bar: the way into search from anywhere in
    // the feed.
    expect(find.byType(HomeHeroSearchField), findsOneWidget);
    await tester.tap(find.byType(HomeHeroSearchField));
    expect(searches, 1);
    // The faded delivery line takes no taps.
    await tester.tap(find.byType(HomeHeroDeliverTo), warnIfMissed: false);
    expect(addressTaps, 0);
  });

  testWidgets('the largest text still fits every row of the header', (
    tester,
  ) async {
    await pumpHero(tester, textScaler: _largestText);

    expect(tester.takeException(), isNull);
    final store = tester.getRect(find.byType(HomeStoreIdentity));
    final address = tester.getRect(find.byType(HomeHeroDeliverTo));
    final search = tester.getRect(find.byType(HomeHeroSearchField));
    expect(store.bottom, lessThanOrEqualTo(address.top));
    expect(address.bottom, lessThanOrEqualTo(search.top));
  });

  testWidgets('assistant disc: beside the bell when the store runs it', (
    tester,
  ) async {
    await pumpHero(tester);
    expect(find.byType(HomeAssistantButton), findsNothing);
    final storeWithout = tester.getRect(find.byType(HomeStoreIdentity));

    await pumpHero(tester, withAssistant: true);
    expect(find.byType(HomeAssistantButton), findsOneWidget);
    final disc = tester.getRect(find.byType(HomeAssistantButton));
    final bell = tester.getRect(find.byType(HomeNotificationsBell));
    final store = tester.getRect(find.byType(HomeStoreIdentity));
    // Before the bell on the same line, and the store row stops before it.
    expect(disc.right, lessThanOrEqualTo(bell.left));
    expect(disc.center.dy, closeTo(bell.center.dy, 0.5));
    expect(store.right, lessThanOrEqualTo(disc.left));
    expect(store.width, lessThan(storeWithout.width));

    await tester.tap(find.byType(HomeAssistantButton));
    expect(assistantTaps, 1);

    // Collapsed: it rides in the bar with the bell, clear of the search pill.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    final pill = tester.getRect(find.byType(HomeHeroSearchField));
    expect(
      pill.right,
      lessThanOrEqualTo(tester.getRect(find.byType(HomeAssistantButton)).left),
    );
  });
}
