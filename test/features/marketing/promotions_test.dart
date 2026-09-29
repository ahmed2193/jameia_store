// Offers + CMS pages: DTOs fed with the live offers payload, the pages
// datasource, the repository (device copy first, failure mapping), the
// "still running" rule and the cubits (saved copy, stale data, reconnect).
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/data/datasources/cache_slots.dart';
import 'package:hero_mart/src/core/data/datasources/catalog_cache_data_source.dart';
import 'package:hero_mart/src/core/data/mappers/offer_mapper.dart';
import 'package:hero_mart/src/core/data/models/catalog_results.dart';
import 'package:hero_mart/src/core/data/models/offer_model.dart';
import 'package:hero_mart/src/core/data/models/remote_payload.dart';
import 'package:hero_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:hero_mart/src/core/domain/entities/offer_entity.dart';
import 'package:hero_mart/src/core/domain/entities/screen_load.dart';
import 'package:hero_mart/src/core/error/exceptions.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/network/dio_consumer.dart';
import 'package:hero_mart/src/core/network/end_points.dart';
import 'package:hero_mart/src/core/storage/cache_owner.dart';
import 'package:hero_mart/src/features/marketing/data/datasources/promotions_cache_data_source.dart';
import 'package:hero_mart/src/features/marketing/data/datasources/promotions_remote_data_source.dart';
import 'package:hero_mart/src/features/marketing/data/models/content_page_model.dart';
import 'package:hero_mart/src/features/marketing/data/repositories/promotions_repository_impl.dart';
import 'package:hero_mart/src/features/marketing/domain/entities/content_page_entity.dart';
import 'package:hero_mart/src/features/marketing/domain/repositories/promotions_repository.dart';
import 'package:hero_mart/src/features/marketing/domain/usecases/watch_content_page_usecase.dart';
import 'package:hero_mart/src/features/marketing/domain/usecases/watch_offers_usecase.dart';
import 'package:hero_mart/src/features/marketing/presentation/cubit/content_page_cubit.dart';
import 'package:hero_mart/src/features/marketing/presentation/cubit/offers_cubit.dart';

import '../../core/data/catalog_test_fakes.dart';
import '../../core/data/snapshot_test_fakes.dart';
import '../../core/network/network_test_fakes.dart';
import '../../core/storage/cache_test_fakes.dart';

/// Rows of `GET /v1/offers` on the live host (2026-09-17), plus one inactive.
const List<Map<String, dynamic>> _liveOffers = [
  {
    '_id': '6aa601198a2745ca86163649',
    'name': 'Free delivery over 5 KWD',
    'status': 'active',
    'trigger': {'type': 'cart_subtotal', 'min': 5000},
    'reward': {'type': 'free_delivery'},
    'priority': 10,
    'stackable': true,
    'branchIds': <String>[],
    'startsAt': '2025-01-01T00:00:00.000Z',
    'endsAt': '2027-12-31T23:59:59.000Z',
    'description': 'Spend 5 KWD or more to unlock free delivery.',
  },
  {
    '_id': '6aa601198a2745ca8616364a',
    'name': '10% off over 15 KWD',
    'status': 'active',
    'trigger': {'type': 'cart_subtotal', 'min': 15000},
    'reward': {
      'type': 'percentage_discount',
      'percent': 10,
      'maxDiscount': 3000,
    },
    'priority': 20,
    'stackable': true,
    'startsAt': '2025-01-01T00:00:00.000Z',
    'endsAt': '2027-12-31T23:59:59.000Z',
  },
  {
    '_id': 'off',
    'name': 'Archived',
    'status': 'archived',
    'trigger': {'type': 'cart_subtotal', 'min': 0},
    'reward': {'type': 'free_delivery'},
    'priority': 99,
  },
];

const ContentPageEntity _about = ContentPageEntity(
  kind: ContentPageKind.about,
  title: 'About',
  body: 'Hi',
);

/// Scripted reads streamed like the cached repository: the saved copy first
/// (when set), then the scripted reply. Each read records its
/// `forceRefresh`.
class _FakeRepository implements PromotionsRepository {
  Either<Failure, List<OfferEntity>> offers = const Right(<OfferEntity>[]);
  List<OfferEntity>? savedOffers;
  Either<Failure, ContentPageEntity> page = const Right(_about);
  ContentPageEntity? savedPage;
  final List<bool> offerReads = [];
  final List<bool> pageReads = [];

  @override
  Stream<DataSnapshot<List<OfferEntity>>> watchOffers({
    bool forceRefresh = false,
  }) {
    offerReads.add(forceRefresh);
    return networkRead(Future.value(offers), saved: savedOffers);
  }

  @override
  Stream<DataSnapshot<ContentPageEntity>> watchContentPage(
    ContentPageKind kind, {
    bool forceRefresh = false,
  }) {
    pageReads.add(forceRefresh);
    return networkRead(Future.value(page), saved: savedPage);
  }
}

class _ScriptedRemote implements PromotionsRemoteDataSource {
  Object? error;
  int pageReads = 0;

  @override
  Future<RemotePayload<ContentPageModel>> getPage(String slug) async {
    pageReads++;
    final current = error;
    if (current != null) throw current;
    final raw = <String, dynamic>{
      'slug': slug,
      'title': 'About Hero',
      'body': 'Text',
    };
    return RemotePayload(ContentPageModel.fromJson(raw), raw);
  }
}

/// The shared catalogue read of the offers, answering the live rows.
class _ScriptedCatalog extends FakeCatalogRemoteDataSource {
  Object? error;
  int offerReads = 0;

  @override
  Future<RemotePayload<List<OfferModel>>> fetchOffers() async {
    offerReads++;
    final current = error;
    if (current != null) throw current;
    final raw = <String, dynamic>{
      CatalogResults.dataKey: _liveOffers,
      'pagination': {'total': 3, 'page': 1, 'limit': 100, 'hasMore': false},
    };
    return RemotePayload(CatalogResults.offers(raw), raw);
  }
}

CacheSlots _slots() => CacheSlots(
  store: InMemoryJsonCacheStore(),
  owner: CacheOwner(),
  locale: FakeLocaleProvider('en'),
);

PromotionsRepositoryImpl _repository(
  _ScriptedRemote remote,
  _ScriptedCatalog catalog, {
  CacheSlots? slots,
}) {
  final cache = slots ?? _slots();
  return PromotionsRepositoryImpl(
    remote,
    catalog,
    cache: PromotionsCacheDataSourceImpl(cache),
    catalogCache: CatalogCacheDataSourceImpl(cache),
  );
}

OffersCubit _offersCubit(_FakeRepository repository) => OffersCubit(
  WatchOffersUseCase(repository),
  now: () => DateTime.utc(2026, 9, 17),
);

ContentPageCubit _pageCubit(_FakeRepository repository) => ContentPageCubit(
  WatchContentPageUseCase(repository),
  kind: ContentPageKind.about,
);

void main() {
  group('offers (live payload)', () {
    test('active only, highest priority first, union fields mapped', () {
      final offers = [for (final row in _liveOffers) OfferModel.fromJson(row)]
          .toEntities();

      expect(
        [for (final offer in offers) offer.name],
        ['10% off over 15 KWD', 'Free delivery over 5 KWD'],
      );
      final percent = offers.first;
      expect(percent.triggerType, OfferTriggerType.cartSubtotal);
      expect(percent.minSubtotalKd, 15);
      expect(percent.rewardType, OfferRewardType.percentageDiscount);
      expect(percent.percent, 10);
      expect(percent.maxDiscountKd, 3);
      expect(percent.stackable, isTrue);
      final delivery = offers.last;
      expect(delivery.rewardType, OfferRewardType.freeDelivery);
      expect(delivery.maxDiscountKd, isNull);
      expect(delivery.description, isNotEmpty);
    });

    test('unknown union kinds map to other; an id-less row is refused', () {
      final offer = OfferModel.fromJson({
        '_id': 'x',
        'trigger': {'type': 'loyalty_tier'},
        'reward': {'type': 'mystery_box'},
      }).toEntity();

      expect(offer.triggerType, OfferTriggerType.other);
      expect(offer.rewardType, OfferRewardType.other);
      expect(
        () => OfferModel.fromJson({'name': 'x'}),
        throwsA(isA<ParsingException>()),
      );
    });

    test(
      'WatchOffersUseCase leaves out an ended offer, the saved copy too',
      () async {
        final ended = OfferEntity(
          id: 'old',
          name: 'old',
          endsAt: DateTime.utc(2026, 9, 1),
        );
        const openEnded = OfferEntity(id: 'open', name: 'open-ended');
        final repository = _FakeRepository()
          ..savedOffers = [ended, openEnded]
          ..offers = Right([
            ended,
            OfferEntity(id: 'live', name: 'live', endsAt: DateTime.utc(2027)),
            openEnded,
          ]);
        final watch = WatchOffersUseCase(repository);

        final snapshots = await watch(
          WatchOffersParams(now: DateTime.utc(2026, 9, 17)),
        ).toList();
        await watch(
          WatchOffersParams(now: DateTime.utc(2026, 9, 17), forceRefresh: true),
        ).drain<void>();

        expect(
          [
            for (final snapshot in snapshots)
              [for (final offer in snapshot.data) offer.id],
          ],
          [
            ['open'],
            ['live', 'open'],
          ],
        );
        expect(snapshots.first.isFromCache, isTrue);
        expect(repository.offerReads, [false, true]);
      },
    );
  });

  group('content pages', () {
    test('the slug enum mirrors the backend', () {
      expect(
        [for (final kind in ContentPageKind.values) kind.slug],
        ['about', 'contact', 'faq', 'privacy', 'terms'],
      );
      expect(ContentPageKind.ofSlug('faq'), ContentPageKind.faq);
      expect(ContentPageKind.ofSlug('careers'), isNull);
    });

    test('a saved page parses back with the DTO; public, one per slug', () {
      final cache = PromotionsCacheDataSourceImpl(_slots());
      final about = cache.page('about')!;

      expect(about.namespace.name, 'marketing.page');
      expect(
        about.parse({'slug': 'about', 'title': 'About', 'body': 'Hi'}).body,
        'Hi',
      );
      expect(
        () => about.parse(const ['not', 'a', 'page']),
        throwsA(isA<ParsingException>()),
      );
    });
  });

  group('PromotionsRemoteDataSourceImpl', () {
    test('getPage GETs /v1/pages/:slug and keeps the raw results', () async {
      final adapter = FakeHttpClientAdapter(
        (_, _) => okBody({
          'slug': 'about',
          'title': 'About Hero',
          'body': 'Hero is your neighborhood grocery.',
        }),
      );
      final dataSource = PromotionsRemoteDataSourceImpl(
        DioConsumer(Dio()..httpClientAdapter = adapter),
      );

      final page = await dataSource.getPage('about');

      expect(adapter.requests.single.path, EndPoints.page('about'));
      expect(page.model.title, 'About Hero');
      expect((page.raw as Map)['slug'], 'about');
    });
  });

  group('PromotionsRepositoryImpl', () {
    test('maps entities; exceptions become failures', () async {
      final remote = _ScriptedRemote();
      final catalog = _ScriptedCatalog();
      final repository = _repository(remote, catalog);

      final offers = await repository.watchOffers().last;
      final page = await repository
          .watchContentPage(ContentPageKind.about)
          .last;
      expect(offers.data, hasLength(2));
      expect(page.data.kind, ContentPageKind.about);
      expect(page.data.title, 'About Hero');

      catalog.error = const RequestTimeoutException();
      remote.error = const NotFoundException('Page not found');
      await expectLater(
        repository.watchOffers(forceRefresh: true),
        emitsError(isA<TimeoutFailure>()),
      );
      await expectLater(
        repository.watchContentPage(ContentPageKind.faq),
        emitsError(isA<NotFoundFailure>()),
      );
    });

    test('offers and a page paint from the device copy', () async {
      final remote = _ScriptedRemote();
      final catalog = _ScriptedCatalog();
      final slots = _slots();
      final repository = _repository(remote, catalog, slots: slots);
      await repository.watchOffers().drain<void>();
      await repository.watchContentPage(ContentPageKind.about).drain<void>();
      await pumpEventQueue();
      catalog.error = const NoInternetConnectionException();
      remote.error = const NoInternetConnectionException();

      final offers = await repository.watchOffers().toList();
      final page = await repository
          .watchContentPage(ContentPageKind.about)
          .toList();

      expect(offers.single.isFromCache, isTrue);
      expect(offers.single.data, hasLength(2));
      expect(page.single.isFromCache, isTrue);
      expect(page.single.data.body, 'Text');
      expect(catalog.offerReads, 1, reason: 'a fresh copy ends the read');
      expect(remote.pageReads, 1);
      // The catalogue's own entry: the product page and the checkout read
      // the same copy.
      expect(
        await CatalogCacheDataSourceImpl(slots).offers()!.read(),
        isNotNull,
      );
    });
  });

  group('OffersCubit', () {
    test('error → retry → loaded; a failed refresh keeps the list', () async {
      final repository = _FakeRepository()
        ..offers = const Left(NetworkFailure('offline'));
      final cubit = _offersCubit(repository);

      await cubit.load();
      expect(cubit.state.status, LoadPhase.error);
      expect(cubit.state.failure, isA<NetworkFailure>());

      repository.offers = const Right([OfferEntity(id: 'a', name: 'A')]);
      await cubit.load();
      expect(cubit.state.offers.single.id, 'a');
      expect(cubit.state.failure, isNull);

      repository.offers = const Left(ServerFailure('down'));
      await cubit.refresh();
      expect(cubit.state.status, LoadPhase.loaded);
      expect(cubit.state.offers.single.id, 'a');
      expect(cubit.state.failure, isA<ServerFailure>());
      expect(cubit.state.load.freshness.refreshFailed, isTrue);
      expect(repository.offerReads, [false, false, true]);
      await cubit.close();
    });

    test('offline with a saved copy: the saved offers, marked stale', () async {
      final repository = _FakeRepository()
        ..savedOffers = const [OfferEntity(id: 'a', name: 'A')]
        ..offers = const Left(NetworkFailure());
      final cubit = _offersCubit(repository);

      await cubit.load();

      expect(cubit.state.status, LoadPhase.loaded);
      expect(cubit.state.offers.single.id, 'a');
      expect(cubit.state.load.freshness.fetchedAt, savedSnapshotAt);
      expect(cubit.state.load.freshness.fromCache, isTrue);
      expect(cubit.state.load.freshness.refreshFailed, isTrue);
      expect(cubit.state.failure, isA<NetworkFailure>());
      await cubit.close();
    });

    test('reconnect refreshes a saved list once, never a fresh one', () async {
      final repository = _FakeRepository()
        ..offers = const Right([OfferEntity(id: 'a', name: 'A')]);
      final cubit = _offersCubit(repository);
      await cubit.load();

      await cubit.onReconnected();
      expect(repository.offerReads, [false], reason: 'fresh: no request');

      repository
        ..savedOffers = const [OfferEntity(id: 'a', name: 'A')]
        ..offers = const Left(NetworkFailure());
      await cubit.load();
      expect(cubit.state.load.freshness.isStale, isTrue);

      repository
        ..savedOffers = null
        ..offers = const Right([OfferEntity(id: 'b', name: 'B')]);
      await cubit.onReconnected();

      expect(repository.offerReads, [false, false, true]);
      expect(cubit.state.offers.single.id, 'b');
      expect(cubit.state.load.freshness.isStale, isFalse);
      await cubit.close();
    });

    test('reconnect after the full-screen error loads the list', () async {
      final repository = _FakeRepository()
        ..offers = const Left(NetworkFailure());
      final cubit = _offersCubit(repository);
      await cubit.load();
      expect(cubit.state.status, LoadPhase.error);

      repository.offers = const Right([OfferEntity(id: 'a', name: 'A')]);
      await cubit.onReconnected();

      expect(cubit.state.status, LoadPhase.loaded);
      expect(cubit.state.offers.single.id, 'a');
      expect(repository.offerReads, [false, true]);
      await cubit.close();
    });
  });

  group('ContentPageCubit', () {
    test('loads the page; an error is retryable', () async {
      final repository = _FakeRepository()
        ..page = const Left(
          ServerFailure('Validation failed', statusCode: 400),
        );
      final cubit = _pageCubit(repository);

      await cubit.load();
      expect(cubit.state.status, LoadPhase.error);
      expect(cubit.state.failure, isA<ServerFailure>());

      repository.page = const Right(
        ContentPageEntity(kind: ContentPageKind.about, title: 'T', body: 'B'),
      );
      await cubit.load();
      expect(cubit.state.page?.body, 'B');
      expect(cubit.state.failure, isNull);
      await cubit.close();
    });

    test('a failed reload keeps the saved page and marks it stale', () async {
      final repository = _FakeRepository()
        ..savedPage = _about
        ..page = const Left(NetworkFailure());
      final cubit = _pageCubit(repository);

      await cubit.load();

      expect(cubit.state.status, LoadPhase.loaded);
      expect(cubit.state.page, _about);
      expect(cubit.state.load.freshness.fromCache, isTrue);
      expect(cubit.state.load.freshness.refreshFailed, isTrue);
      await cubit.close();
    });

    test('reconnect refreshes a saved or failed page', () async {
      final repository = _FakeRepository()..page = const Left(NetworkFailure());
      final cubit = _pageCubit(repository);
      await cubit.load();
      expect(cubit.state.status, LoadPhase.error);

      repository.page = const Right(_about);
      await cubit.onReconnected();
      await cubit.onReconnected();

      expect(cubit.state.page, _about);
      expect(repository.pageReads, [false, true], reason: 'fresh after one');
      await cubit.close();
    });
  });
}
