import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:hero_mart/src/core/domain/entities/catalog_category_entity.dart';
import 'package:hero_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/usecase/watch_params.dart';
import 'package:hero_mart/src/features/home/domain/entities/home_bootstrap.dart';
import 'package:hero_mart/src/features/home/domain/entities/home_feed.dart';
import 'package:hero_mart/src/features/home/domain/entities/home_section_entity.dart';
import 'package:hero_mart/src/features/home/domain/entities/home_slide_entity.dart';
import 'package:hero_mart/src/features/home/domain/repositories/home_repository.dart';
import 'package:hero_mart/src/features/home/domain/usecases/watch_home_feed_usecase.dart';

/// `results` of `GET /v1/home` captured from the live host (2026-09-17).
Map<String, dynamic> liveHomeJson() => _fixture('home_en.json');

/// `results` of `GET /v1/init` captured from the live host (2026-09-17).
Map<String, dynamic> liveInitJson() => _fixture('init_en.json');

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('test/features/home/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;

HomeFeed feedOf(String slideId) => HomeFeed(
  slides: [HomeSlideEntity(id: slideId, imageUrl: 'https://x/$slideId.png')],
  sections: const <HomeSectionEntity>[],
  categories: CatalogCategoryTree.empty,
);

const HomeMarketingPopup sessionPopup = HomeMarketingPopup(
  id: 'p-session',
  title: 'Welcome',
);

const HomeMarketingPopup dailyPopup = HomeMarketingPopup(
  id: 'p-day',
  title: 'Deal of the day',
  frequency: HomePopupFrequency.day,
);

final DateTime savedAtTime = DateTime.utc(2026, 9, 17, 9);
final DateTime fetchedAtTime = DateTime.utc(2026, 9, 17, 10);

/// A cached read as the repository streams it: the saved copy (when given
/// and not forced), then the server's reply or its failure.
Stream<DataSnapshot<T>> scriptedRead<T>({
  required T? cached,
  required Either<Failure, T> network,
}) async* {
  if (cached != null) {
    yield DataSnapshot<T>(
      data: cached,
      fetchedAt: savedAtTime,
      origin: SnapshotOrigin.cache,
    );
  }
  yield* network.fold(
    Stream<DataSnapshot<T>>.error,
    (data) => Stream.value(
      DataSnapshot<T>(
        data: data,
        fetchedAt: fetchedAtTime,
        origin: SnapshotOrigin.network,
      ),
    ),
  );
}

/// In-memory [HomeRepository]: scripted copies + replies, the reads it was
/// asked for (`true` = forced) and the popup stamps it was asked to save.
class FakeHomeRepository implements HomeRepository {
  Either<Failure, HomeFeed> feed = Right(feedOf('s1'));
  Either<Failure, HomeBootstrap> bootstrap = const Right(HomeBootstrap.empty);
  HomeFeed? cachedFeed;
  HomeBootstrap? cachedBootstrap;
  final List<bool> feedReads = <bool>[];
  final Map<String, String> shownDays = <String, String>{};
  Failure? stampReadFailure;
  Failure? stampWriteFailure;
  Either<Failure, int> ordersCount = const Right(0);
  int orderCounts = 0;

  /// When set, every order count waits on a gate of its own, in call order.
  List<Completer<Either<Failure, int>>>? orderGates;

  @override
  Stream<DataSnapshot<HomeFeed>> watchHomeFeed({bool forceRefresh = false}) {
    feedReads.add(forceRefresh);
    return scriptedRead(
      cached: forceRefresh ? null : cachedFeed,
      network: feed,
    );
  }

  @override
  Stream<DataSnapshot<HomeBootstrap>> watchBootstrap({
    bool forceRefresh = false,
  }) => scriptedRead(
    cached: forceRefresh ? null : cachedBootstrap,
    network: bootstrap,
  );

  @override
  Future<Either<Failure, int>> countOrders() async {
    orderCounts++;
    final gates = orderGates;
    if (gates == null) return ordersCount;
    final gate = Completer<Either<Failure, int>>();
    gates.add(gate);
    return gate.future;
  }

  @override
  Either<Failure, String?> popupShownDay(String popupId) {
    final failure = stampReadFailure;
    return failure != null ? Left(failure) : Right(shownDays[popupId]);
  }

  @override
  Future<Either<Failure, Unit>> savePopupShownDay(
    String popupId,
    String day,
  ) async {
    final failure = stampWriteFailure;
    if (failure != null) return Left(failure);
    shownDays[popupId] = day;
    return const Right(unit);
  }
}

/// A feed use case whose reads are driven by the test, to stage races: each
/// call opens a stream the test feeds through [reads].
class GatedWatchHomeFeed implements WatchHomeFeedUseCase {
  final List<StreamController<DataSnapshot<HomeFeed>>> reads = [];

  @override
  Stream<DataSnapshot<HomeFeed>> call(WatchParams params) {
    final controller = StreamController<DataSnapshot<HomeFeed>>();
    reads.add(controller);
    return controller.stream;
  }
}

DataSnapshot<HomeFeed> networkFeed(String slideId) => DataSnapshot(
  data: feedOf(slideId),
  fetchedAt: fetchedAtTime,
  origin: SnapshotOrigin.network,
);

DataSnapshot<HomeFeed> cachedFeedSnapshot(String slideId) => DataSnapshot(
  data: feedOf(slideId),
  fetchedAt: savedAtTime,
  origin: SnapshotOrigin.cache,
);
