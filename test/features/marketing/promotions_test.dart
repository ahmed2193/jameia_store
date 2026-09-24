// Offers + CMS pages: DTOs fed with the live offers payload, datasource,
// repository failure mapping, the "still running" rule and the cubits.
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/exceptions.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/network/dio_consumer.dart';
import 'package:jameia_mart/src/core/network/end_points.dart';
import 'package:jameia_mart/src/features/marketing/data/datasources/promotions_remote_data_source.dart';
import 'package:jameia_mart/src/features/marketing/data/mappers/promotions_mapper.dart';
import 'package:jameia_mart/src/features/marketing/data/models/content_page_model.dart';
import 'package:jameia_mart/src/features/marketing/data/models/offer_model.dart';
import 'package:jameia_mart/src/features/marketing/data/repositories/promotions_repository_impl.dart';
import 'package:jameia_mart/src/features/marketing/domain/entities/content_page_entity.dart';
import 'package:jameia_mart/src/features/marketing/domain/entities/offer_entity.dart';
import 'package:jameia_mart/src/features/marketing/domain/repositories/promotions_repository.dart';
import 'package:jameia_mart/src/features/marketing/domain/usecases/get_content_page_usecase.dart';
import 'package:jameia_mart/src/features/marketing/domain/usecases/get_offers_usecase.dart';
import 'package:jameia_mart/src/features/marketing/presentation/cubit/content_page_cubit.dart';
import 'package:jameia_mart/src/features/marketing/presentation/cubit/content_page_state.dart';
import 'package:jameia_mart/src/features/marketing/presentation/cubit/offers_cubit.dart';
import 'package:jameia_mart/src/features/marketing/presentation/cubit/offers_state.dart';

import '../../core/network/network_test_fakes.dart';

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

class _FakeRepository implements PromotionsRepository {
  Either<Failure, List<OfferEntity>> offers = const Right(<OfferEntity>[]);
  Either<Failure, ContentPageEntity> page = const Right(
    ContentPageEntity(kind: ContentPageKind.about, title: 'About', body: 'Hi'),
  );

  @override
  Future<Either<Failure, List<OfferEntity>>> getOffers() async => offers;

  @override
  Future<Either<Failure, ContentPageEntity>> getContentPage(
    ContentPageKind kind,
  ) async => page;
}

class _ScriptedRemote implements PromotionsRemoteDataSource {
  Object? error;

  @override
  Future<List<OfferModel>> getOffers() async {
    final current = error;
    if (current != null) throw current;
    return [for (final row in _liveOffers) OfferModel.fromJson(row)];
  }

  @override
  Future<ContentPageModel> getPage(String slug) async {
    final current = error;
    if (current != null) throw current;
    return ContentPageModel(slug: slug, title: 'About Jm3eia', body: 'Text');
  }
}

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

    test('GetOffersUseCase leaves out an offer that already ended', () async {
      final repository = _FakeRepository()
        ..offers = Right([
          OfferEntity(id: 'old', name: 'old', endsAt: DateTime.utc(2026, 9, 1)),
          OfferEntity(id: 'live', name: 'live', endsAt: DateTime.utc(2027)),
          const OfferEntity(id: 'open', name: 'open-ended'),
        ]);

      final offers = await GetOffersUseCase(repository)(
        GetOffersParams(now: DateTime.utc(2026, 9, 17)),
      );

      expect(
        [for (final offer in offers.getOrElse(() => [])) offer.id],
        ['live', 'open'],
      );
    });
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
  });

  group('PromotionsRemoteDataSourceImpl', () {
    late FakeHttpClientAdapter adapter;

    PromotionsRemoteDataSourceImpl build(FakeHttpClientAdapter transport) {
      adapter = transport;
      return PromotionsRemoteDataSourceImpl(
        DioConsumer(Dio()..httpClientAdapter = adapter),
      );
    }

    test('getOffers GETs /v1/offers and skips a malformed row', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody({
            'data': [
              ..._liveOffers,
              {'name': 'no id'},
            ],
            'pagination': {
              'total': 4,
              'page': 1,
              'limit': 100,
              'hasMore': false,
            },
          }),
        ),
      );

      final offers = await dataSource.getOffers();

      expect(adapter.requests.single.path, EndPoints.offers);
      expect(adapter.requests.single.queryParameters, {
        'page': 1,
        'limit': 100,
      });
      expect(offers, hasLength(3));
    });

    test('getPage GETs /v1/pages/:slug', () async {
      final dataSource = build(
        FakeHttpClientAdapter(
          (_, _) => okBody({
            'slug': 'about',
            'title': 'About Jm3eia',
            'body': 'Jm3eia is your neighborhood grocery.',
          }),
        ),
      );

      final page = await dataSource.getPage('about');

      expect(adapter.requests.single.path, EndPoints.page('about'));
      expect(page.title, 'About Jm3eia');
    });
  });

  group('PromotionsRepositoryImpl', () {
    test('maps entities; exceptions become failures', () async {
      final remote = _ScriptedRemote();
      final repository = PromotionsRepositoryImpl(remote);

      final offers = await repository.getOffers();
      final page = await repository.getContentPage(ContentPageKind.about);
      expect(offers.getOrElse(() => []), hasLength(2));
      expect(
        page.getOrElse(() => throw StateError('left')).kind,
        ContentPageKind.about,
      );

      remote.error = const RequestTimeoutException();
      final failed = await repository.getOffers();
      expect(
        failed.swap().getOrElse(() => throw StateError('right')),
        isA<TimeoutFailure>(),
      );
    });
  });

  group('cubits', () {
    test(
      'OffersCubit: error → retry → loaded; a failed refresh keeps the list',
      () async {
        final repository = _FakeRepository()
          ..offers = const Left(NetworkFailure('offline'));
        final cubit = OffersCubit(
          GetOffersUseCase(repository),
          now: () => DateTime.utc(2026, 9, 17),
        );

        await cubit.load();
        expect(cubit.state.status, OffersStatus.error);

        repository.offers = const Right([OfferEntity(id: 'a', name: 'A')]);
        await cubit.load();
        expect(cubit.state.offers.single.id, 'a');

        repository.offers = const Left(ServerFailure('down'));
        await cubit.refresh();
        expect(cubit.state.status, OffersStatus.loaded);
        expect(cubit.state.offers.single.id, 'a');
        expect(cubit.state.failure, isA<ServerFailure>());
        await cubit.close();
      },
    );

    test('ContentPageCubit loads the page; an error is retryable', () async {
      final repository = _FakeRepository()
        ..page = const Left(
          ServerFailure('Validation failed', statusCode: 400),
        );
      final cubit = ContentPageCubit(
        GetContentPageUseCase(repository),
        kind: ContentPageKind.about,
      );

      await cubit.load();
      expect(cubit.state.status, ContentPageStatus.error);

      repository.page = const Right(
        ContentPageEntity(kind: ContentPageKind.about, title: 'T', body: 'B'),
      );
      await cubit.load();
      expect(cubit.state.page?.body, 'B');
      await cubit.close();
    });
  });
}
