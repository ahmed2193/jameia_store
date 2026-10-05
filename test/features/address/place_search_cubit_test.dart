// The place search: asks once the typing pauses, keeps only the latest
// answer, retries a failed search, looks up a picked place once and ends
// the search session when it closes.
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/domain/entities/geo_point_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/address/domain/entities/place_spot.dart';
import 'package:hero_mart/src/features/address/domain/entities/place_suggestion.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/place_search_cubit.dart';
import 'package:hero_mart/src/features/address/presentation/cubit/place_search_state.dart';

import 'address_picker_test_fakes.dart';

void main() {
  late FakeSearchPlacesUseCase search;
  late FakeLocatePlaceUseCase locate;
  late FakeEndPlaceSearchUseCase end;
  late FakeGetDeliveryAreasUseCase areas;

  const salmiyaAnswer = PlaceSuggestion(
    id: 'p1',
    title: 'Salmiya',
    subtitle: 'Hawalli Governorate',
    source: PlaceSource.google,
  );

  PlaceSearchCubit build({GeoPointEntity? near}) => PlaceSearchCubit(
    searchPlaces: search,
    locatePlace: locate,
    endSearch: end,
    deliveryAreas: areas,
    near: near,
  );

  Future<void> pause() => Future<void>.delayed(PlaceSearchCubit.debounce * 2);

  setUp(() {
    search = FakeSearchPlacesUseCase()..result = const Right([salmiyaAnswer]);
    locate = FakeLocatePlaceUseCase();
    end = FakeEndPlaceSearchUseCase();
    areas = FakeGetDeliveryAreasUseCase();
  });

  test('lists the delivery areas before anything is typed, and keeps them '
      'while the customer types', () async {
    const jahraArea = PlaceSuggestion(
      id: 'area:jahra',
      title: 'Jahra',
      location: jahra,
      source: PlaceSource.area,
    );
    areas.result = const Right([jahraArea]);
    final cubit = build(near: salmiya);
    addTearDown(cubit.close);

    cubit.showAreas(languageCode: 'ar');
    expect(areas.asked, ['ar']);
    expect(areas.nearAsked, [salmiya]); // each says how far from the map
    expect(cubit.state.areas, [jahraArea]);

    cubit.queryChanged('sal', languageCode: 'ar');
    await pause();
    cubit.queryChanged('', languageCode: 'ar');
    expect(cubit.state.status, PlaceSearchStatus.idle);
    expect(cubit.state.areas, [jahraArea]);
  });

  test("an answer's ↖ puts its name in the search box once and asks again "
      'for it', () async {
    final cubit = build(near: salmiya);
    addTearDown(cubit.close);
    final states = <PlaceSearchState>[];
    final watching = cubit.stream.listen(states.add);
    addTearDown(watching.cancel);

    cubit.fill(salmiyaAnswer, languageCode: 'ar');
    await pause();

    expect(states.first.fill, 'Salmiya');
    expect(states.skip(1).map((state) => state.fill), everyElement(isNull));
    expect(search.calls.single.input, 'Salmiya');
    expect(search.calls.single.languageCode, 'ar');
    expect(cubit.state.query, 'Salmiya');
    expect(cubit.state.status, PlaceSearchStatus.results);
  });

  test("a ↖ on the words already searched asks nothing again", () async {
    final cubit = build();
    addTearDown(cubit.close);
    cubit.queryChanged('Salmiya', languageCode: 'en');
    await pause();
    expect(search.calls, hasLength(1));

    final states = <PlaceSearchState>[];
    final watching = cubit.stream.listen(states.add);
    addTearDown(watching.cancel);
    cubit.fill(salmiyaAnswer, languageCode: 'en');
    await pause();

    expect(states.single.fill, 'Salmiya');
    expect(search.calls, hasLength(1));
    expect(cubit.state.status, PlaceSearchStatus.results);
  });

  test("no ↖ while a picked place is looked up", () async {
    final gate = Completer<void>();
    locate.gate = gate;
    final cubit = build();
    addTearDown(cubit.close);
    unawaited(cubit.pick(salmiyaAnswer, languageCode: 'en'));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.lookingUpId, 'p1');

    cubit.fill(salmiyaAnswer, languageCode: 'en');
    await pause();
    expect(cubit.state.fill, isNull);
    expect(search.calls, isEmpty);
    gate.complete();
  });

  test('too little typed: nothing is asked', () async {
    final cubit = build();
    addTearDown(cubit.close);
    cubit.queryChanged('s', languageCode: 'en');
    await pause();
    expect(cubit.state.status, PlaceSearchStatus.idle);
    expect(search.calls, isEmpty);
  });

  test(
    'asks once the typing pauses, for the latest words, near the map',
    () async {
      final cubit = build(near: salmiya);
      addTearDown(cubit.close);
      cubit
        ..queryChanged('sa', languageCode: 'ar')
        ..queryChanged('sal', languageCode: 'ar')
        ..queryChanged('salm ', languageCode: 'ar');
      expect(cubit.state.status, PlaceSearchStatus.loading);
      await pause();

      expect(search.calls.single.input, 'salm');
      expect(search.calls.single.languageCode, 'ar');
      expect(search.calls.single.near, salmiya);
      expect(cubit.state.status, PlaceSearchStatus.results);
      expect(cubit.state.suggestions, [salmiyaAnswer]);
      expect(cubit.state.creditsGoogle, isTrue);
    },
  );

  test('an answer to older words is dropped', () async {
    final gate = Completer<void>();
    search.gate = gate;
    final cubit = build();
    addTearDown(cubit.close);
    cubit.queryChanged('salmiya', languageCode: 'en');
    await pause(); // asked, held on the gate
    cubit.queryChanged('s', languageCode: 'en'); // back to idle
    gate.complete();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, PlaceSearchStatus.idle);
    expect(cubit.state.suggestions, isEmpty);
  });

  test('nothing found is its own state', () async {
    search.result = const Right([]);
    final cubit = build();
    addTearDown(cubit.close);
    cubit.queryChanged('zzzz', languageCode: 'en');
    await pause();
    expect(cubit.state.status, PlaceSearchStatus.empty);
  });

  test('a failed search keeps the failure; retry asks again at once', () async {
    search.result = const Left(NetworkFailure());
    final cubit = build(near: jahra);
    addTearDown(cubit.close);
    cubit.queryChanged('salmiya', languageCode: 'en');
    await pause();
    expect(cubit.state.status, PlaceSearchStatus.failed);
    expect(cubit.state.failure, const NetworkFailure());

    search.result = const Right([salmiyaAnswer]);
    cubit.retry();
    expect(cubit.state.status, PlaceSearchStatus.loading);
    await Future<void>.delayed(Duration.zero);

    expect(search.calls, hasLength(2));
    expect(search.calls.last.input, 'salmiya');
    expect(search.calls.last.near, jahra);
    expect(cubit.state.status, PlaceSearchStatus.results);
  });

  test('a picked answer is looked up once, then handed over', () async {
    final gate = Completer<void>();
    locate.gate = gate;
    final cubit = build();
    addTearDown(cubit.close);

    final picking = cubit.pick(salmiyaAnswer, languageCode: 'en');
    expect(cubit.state.lookingUpId, 'p1');
    await cubit.pick(salmiyaAnswer, languageCode: 'en'); // ignored
    gate.complete();
    await picking;

    expect(locate.calls, hasLength(1));
    expect(cubit.state.lookingUpId, isNull);
    expect(
      cubit.state.picked,
      const PlaceSpot(location: salmiya, title: 'Salmiya'),
    );
  });

  test('a look-up that fails says so and frees the row', () async {
    locate.result = const Left(TimeoutFailure());
    final cubit = build();
    addTearDown(cubit.close);

    await cubit.pick(salmiyaAnswer, languageCode: 'en');

    expect(cubit.state.pickFailure, const TimeoutFailure());
    expect(cubit.state.lookingUpId, isNull);
    expect(cubit.state.picked, isNull);
  });

  test('closing ends the search session', () async {
    final cubit = build();
    await cubit.close();
    expect(end.calls, 1);
  });
}
