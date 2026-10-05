// The address search page over a GoRouter: what it shows before, during and
// after a search, and what it hands back to the map picker.
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/config/theme/app_text_styles.dart';
import 'package:hero_mart/src/config/theme/app_theme.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/address/domain/entities/map_destination.dart';
import 'package:hero_mart/src/features/address/domain/entities/pinned_place.dart';
import 'package:hero_mart/src/features/address/domain/entities/place_spot.dart';
import 'package:hero_mart/src/features/address/domain/entities/place_suggestion.dart';
import 'package:hero_mart/src/features/address/domain/entities/text_match.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/place_search_cubit.dart';
import 'package:hero_mart/src/features/address/presentation/pages/address_search_page.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_search/place_suggestion_row.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'address_picker_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSearchPlacesUseCase search;
  late FakeLocatePlaceUseCase locate;
  late FakeEndPlaceSearchUseCase end;
  late FakeGetDeliveryAreasUseCase areas;

  const marina = PlaceSuggestion(
    id: 'p1',
    title: 'Marina Mall',
    subtitle: 'Salmiya, Kuwait',
    titleMatches: [TextMatch(0, 4)],
    distanceMeters: 1200,
    source: PlaceSource.google,
  );

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  setUp(() {
    search = FakeSearchPlacesUseCase()..result = const Right([marina]);
    locate = FakeLocatePlaceUseCase()
      ..result = const Right(
        PlaceSpot(location: salmiya, title: 'Marina Mall'),
      );
    end = FakeEndPlaceSearchUseCase();
    areas = FakeGetDeliveryAreasUseCase();
    if (sl.isRegistered<PlaceSearchCubit>()) sl.unregister<PlaceSearchCubit>();
    sl.registerFactoryParam<PlaceSearchCubit, GeoPointEntity?, void>(
      (near, _) => PlaceSearchCubit(
        searchPlaces: search,
        locatePlace: locate,
        endSearch: end,
        deliveryAreas: areas,
        near: near,
      ),
    );
  });

  tearDown(() => sl.unregister<PlaceSearchCubit>());

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// A launcher opens the search near Salmiya and keeps what it answers.
  Future<List<Object?>> pumpSearch(WidgetTester tester) async {
    final answers = <Object?>[];
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () async => answers.add(
                await context.push<MapDestination>(
                  Routes.addressSearch,
                  extra: salmiya,
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
        GoRoute(
          path: Routes.addressSearch,
          builder: (_, state) => const AddressSearchPage(near: salmiya),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await settle(tester);
    await tester.tap(find.text('open'));
    await settle(tester);
    return answers;
  }

  Future<void> teardownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  testWidgets('before anything is typed: my location and how to search', (
    tester,
  ) async {
    await pumpSearch(tester);

    expect(find.text('Use my current location'), findsOneWidget);
    expect(
      find.text('Type your area or street, then fine-tune the pin on the map.'),
      findsOneWidget,
    );
    expect(search.calls, isEmpty);

    await teardownApp(tester);
  });

  testWidgets('answers near the map, with the distance and the Google '
      'credit; a pick hands the place to the map', (tester) async {
    final answers = await pumpSearch(tester);

    await tester.enterText(find.byType(TextField), 'mari');
    await settle(tester);

    expect(search.calls.single.input, 'mari');
    expect(search.calls.single.near, salmiya);
    expect(find.text('Marina Mall', findRichText: true), findsOneWidget);
    expect(find.text('Salmiya, Kuwait'), findsOneWidget);
    expect(find.text('1.2 km'), findsOneWidget);
    expect(find.text('Google Maps'), findsOneWidget);

    await tester.tap(find.text('Marina Mall', findRichText: true));
    await settle(tester);

    expect(locate.calls.single.suggestion, marina);
    expect(find.byType(AddressSearchPage), findsNothing);
    expect(answers, [
      const PlaceDestination(
        PlaceSpot(location: salmiya, title: 'Marina Mall'),
      ),
    ]);

    await teardownApp(tester);
  });

  testWidgets('before anything is typed, the areas Hero delivers to; a '
      'tapped one sends the map to its streets', (tester) async {
    const jahraArea = PlaceSuggestion(
      id: 'area:jahra',
      title: 'Jahra',
      subtitle: 'Jahra Governorate',
      distanceMeters: 41300,
      location: GeoPointEntity(lat: 29.3375, lng: 47.6581),
      source: PlaceSource.area,
    );
    areas.result = const Right([jahraArea]);
    locate.result = const Right(
      PlaceSpot(
        location: GeoPointEntity(lat: 29.3375, lng: 47.6581),
        title: 'Jahra',
        isArea: true,
      ),
    );
    final answers = await pumpSearch(tester);

    expect(areas.asked, ['en']);
    expect(areas.nearAsked, [salmiya]);
    expect(find.text('Areas we deliver to'), findsOneWidget);
    // Google Maps rows: the governorate and the country under the name, how
    // far under the pin; a list to pick from, so no ↖.
    expect(find.text('Jahra Governorate, Kuwait'), findsOneWidget);
    expect(find.text('41.3 km'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('in the search')), findsNothing);
    await tester.tap(find.text('Jahra', findRichText: true));
    await settle(tester);

    expect(locate.calls.single.suggestion, jahraArea);
    expect(answers, [
      const PlaceDestination(
        PlaceSpot(
          location: GeoPointEntity(lat: 29.3375, lng: 47.6581),
          title: 'Jahra',
          isArea: true,
        ),
      ),
    ]);

    await teardownApp(tester);
  });

  testWidgets("an answer's ↖ puts its name in the search box and searches "
      'it — nothing is picked', (tester) async {
    await pumpSearch(tester);
    await tester.enterText(find.byType(TextField), 'mari');
    await settle(tester);

    await tester.tap(find.bySemanticsLabel('Use “Marina Mall” in the search'));
    await settle(tester);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'Marina Mall');
    expect(
      field.controller?.selection,
      const TextSelection.collapsed(offset: 11),
    );
    expect(field.focusNode?.hasFocus, isTrue);
    expect(search.calls.map((call) => call.input), ['mari', 'Marina Mall']);
    expect(locate.calls, isEmpty);
    expect(find.byType(AddressSearchPage), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('a spot the map found reads like Google Maps: its name over '
      'the street, block and area there', (tester) async {
    const tower = GeoPointEntity(lat: 29.3786, lng: 47.9925);
    search.result = const Right([
      PlaceSuggestion(
        id: 'geocoder:tower',
        title: 'Al Hamra Tower',
        titleMatches: [TextMatch(3, 8)],
        distanceMeters: 640,
        location: tower,
        place: PinnedPlace(
          location: tower,
          name: 'Al Hamra Tower',
          area: 'Sharq',
          block: '3',
          street: 'Al Shuhada St',
        ),
        source: PlaceSource.geocoder,
      ),
    ]);
    await pumpSearch(tester);
    await tester.enterText(find.byType(TextField), 'hamra');
    await settle(tester);

    expect(find.text('Al Hamra Tower', findRichText: true), findsOneWidget);
    expect(find.text('Al Shuhada St, Block 3, Sharq, Kuwait'), findsOneWidget);
    expect(find.text('640 m'), findsOneWidget);
    expect(find.text('Google Maps'), findsNothing);

    await teardownApp(tester);
  });

  testWidgets('a bold stretch never cuts an Arabic word apart; a Latin one '
      'stays as typed', (tester) async {
    List<String> boldIn(String title) {
      final rich = tester.widget<RichText>(
        find.byWidgetPredicate(
          (widget) => widget is RichText && widget.text.toPlainText() == title,
        ),
      );
      final bold = <String>[];
      rich.text.visitChildren((span) {
        final text = span is TextSpan ? span.text : null;
        if (text != null && span.style?.fontWeight == AppTextStyles.bold) {
          bold.add(text);
        }
        return true;
      });
      return bold;
    }

    Future<void> show(String title, List<TextMatch> matches) =>
        tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Material(
              child: PlaceSuggestionRow(
                suggestion: PlaceSuggestion(
                  id: 'area:x',
                  title: title,
                  titleMatches: matches,
                  source: PlaceSource.area,
                ),
                lookingUp: false,
                onTap: () {},
              ),
            ),
          ),
        );

    // "سالم" typed: inside "السالم" — the whole word goes bold.
    await show('صباح السالم', const [TextMatch(7, 11)]);
    expect(boldIn('صباح السالم'), ['السالم']);
    // "صب" typed: the start of "صباح" — the word, not two letters of it.
    await show('صباح السالم', const [TextMatch(0, 2)]);
    expect(boldIn('صباح السالم'), ['صباح']);
    await show('Salmiya', const [TextMatch(0, 3)]);
    expect(boldIn('Salmiya'), ['Sal']);
  });

  testWidgets('"Use my current location" sends the map to the device', (
    tester,
  ) async {
    final answers = await pumpSearch(tester);

    await tester.tap(find.text('Use my current location'));
    await settle(tester);

    expect(answers, [const MyLocationDestination()]);

    await teardownApp(tester);
  });

  testWidgets('nothing found says so', (tester) async {
    search.result = const Right([]);
    await pumpSearch(tester);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await settle(tester);

    expect(find.text('No places found'), findsOneWidget);
    expect(find.text('Use my current location'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('a place that cannot be looked up says why and stays', (
    tester,
  ) async {
    locate.result = const Left(ServerFailure('Place not available'));
    final answers = await pumpSearch(tester);

    await tester.enterText(find.byType(TextField), 'mari');
    await settle(tester);
    await tester.tap(find.text('Marina Mall', findRichText: true));
    await settle(tester);

    expect(find.text('Place not available'), findsOneWidget);
    expect(find.byType(AddressSearchPage), findsOneWidget);
    expect(answers, isEmpty);

    await teardownApp(tester);
  });

  testWidgets('leaving ends the search session', (tester) async {
    await pumpSearch(tester);
    await tester.enterText(find.byType(TextField), 'mari');
    await settle(tester);

    await tester.tap(find.byTooltip('Back'));
    await settle(tester);

    expect(find.byType(AddressSearchPage), findsNothing);
    expect(end.calls, 1);

    await teardownApp(tester);
  });
}
