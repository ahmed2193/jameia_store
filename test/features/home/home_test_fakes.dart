import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_category_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/usecase/usecase.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_bootstrap.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_feed.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_section_entity.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_slide_entity.dart';
import 'package:jameia_mart/src/features/home/domain/repositories/home_repository.dart';
import 'package:jameia_mart/src/features/home/domain/usecases/get_home_bootstrap_usecase.dart';
import 'package:jameia_mart/src/features/home/domain/usecases/get_home_feed_usecase.dart';

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

/// In-memory [HomeRepository]: scripted replies + the popup stamps it was
/// asked to save.
class FakeHomeRepository implements HomeRepository {
  Either<Failure, HomeFeed> feed = Right(feedOf('s1'));
  Either<Failure, HomeBootstrap> bootstrap = const Right(HomeBootstrap.empty);
  final Map<String, String> shownDays = <String, String>{};
  Failure? stampReadFailure;
  Failure? stampWriteFailure;

  @override
  Future<Either<Failure, HomeFeed>> getHomeFeed() async => feed;

  @override
  Future<Either<Failure, HomeBootstrap>> getBootstrap() async => bootstrap;

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

/// A feed use case whose replies are released by the test, to stage races.
class GatedGetHomeFeed implements GetHomeFeedUseCase {
  final List<Completer<Either<Failure, HomeFeed>>> calls = [];

  @override
  Future<Either<Failure, HomeFeed>> call(NoParams params) {
    final completer = Completer<Either<Failure, HomeFeed>>();
    calls.add(completer);
    return completer.future;
  }
}

class StubGetHomeBootstrap implements GetHomeBootstrapUseCase {
  StubGetHomeBootstrap(this.reply);

  Either<Failure, HomeBootstrap> reply;
  int calls = 0;

  @override
  Future<Either<Failure, HomeBootstrap>> call(NoParams params) async {
    calls++;
    return reply;
  }
}
