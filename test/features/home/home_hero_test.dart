// The home hero as the storefront header: the delivery line sits on the brand
// band with the search field under it, and the search field stays in the bar
// once the feed has scrolled.
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/config/theme/app_colors.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_hero_deliver_to.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_hero_delegate.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_hero_search_field.dart';
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

  late int searches;
  late int addressTaps;

  Future<void> pumpHero(WidgetTester tester) {
    searches = 0;
    addressTaps = 0;
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: HomeHeroDelegate(
                  placeLabel: 'Apartment',
                  topPad: 0,
                  onAddressTap: () => addressTaps++,
                  onSearch: () => searches++,
                  onNotifications: () {},
                  hasUnreadNotifications: false,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 2000)),
            ],
          ),
        ),
      ),
    );
  }

  double deliverOpacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find
            .ancestor(
              of: find.byType(HomeHeroDeliverTo),
              matching: find.byType(Opacity),
            )
            .first,
      )
      .opacity;

  HomeHeroSearchField searchField(WidgetTester tester) =>
      tester.widget<HomeHeroSearchField>(find.byType(HomeHeroSearchField));

  testWidgets('expanded: the delivery line over an elevated white field', (
    tester,
  ) async {
    await pumpHero(tester);

    expect(deliverOpacity(tester), 1.0);
    expect(
      find.textContaining('Apartment', findRichText: true),
      findsOneWidget,
    );
    expect(searchField(tester).fill, AppColors.white);
    expect(
      searchField(tester).shadowAlpha,
      HomeHeroSearchField.restingShadowAlpha,
    );

    await tester.tap(find.byType(HomeHeroDeliverTo));
    expect(addressTaps, 1);
  });

  testWidgets('collapsed: the delivery line goes, the search field stays', (
    tester,
  ) async {
    await pumpHero(tester);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    expect(deliverOpacity(tester), 0.0);
    // Still there, now flat and grey against the white bar.
    expect(find.byType(HomeHeroSearchField), findsOneWidget);
    expect(searchField(tester).fill, AppColors.smallBackground);
    expect(searchField(tester).shadowAlpha, 0.0);

    // And still the way into search from anywhere in the feed.
    await tester.tap(find.byType(HomeHeroSearchField));
    expect(searches, 1);
    // The faded delivery line takes no taps.
    await tester.tap(find.byType(HomeHeroDeliverTo), warnIfMissed: false);
    expect(addressTaps, 0);
  });
}
