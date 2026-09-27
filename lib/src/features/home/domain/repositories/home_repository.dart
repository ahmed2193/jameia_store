import 'package:dartz/dartz.dart';

import '../../../../core/domain/entities/data_snapshot.dart';
import '../../../../core/error/failures.dart';
import '../entities/home_bootstrap.dart';
import '../entities/home_feed.dart';

/// Read boundary of the home tab (Hero backend, public routes).
abstract class HomeRepository {
  /// `GET /v1/home` — the whole screen in one reply: the device copy first
  /// (when there is one), then the server's unless the copy is fresh.
  /// [forceRefresh] skips the copy. Failures arrive on the error channel.
  Stream<DataSnapshot<HomeFeed>> watchHomeFeed({bool forceRefresh = false});

  /// `GET /v1/init` — delivery context, Pro programme, marketing popups;
  /// read like [watchHomeFeed].
  Stream<DataSnapshot<HomeBootstrap>> watchBootstrap({
    bool forceRefresh = false,
  });

  /// The calendar day (`YYYY-MM-DD`) a popup was last shown on this device, or
  /// `null`.
  Either<Failure, String?> popupShownDay(String popupId);

  Future<Either<Failure, Unit>> savePopupShownDay(String popupId, String day);
}
