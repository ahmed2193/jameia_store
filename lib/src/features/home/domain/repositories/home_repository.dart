import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/home_bootstrap.dart';
import '../entities/home_feed.dart';

/// Read boundary of the home tab (jm3eia backend, public routes).
abstract class HomeRepository {
  /// `GET /v1/home` — the whole screen in one reply.
  Future<Either<Failure, HomeFeed>> getHomeFeed();

  /// `GET /v1/init` — delivery context, Pro programme, marketing popups.
  Future<Either<Failure, HomeBootstrap>> getBootstrap();

  /// The calendar day (`YYYY-MM-DD`) a popup was last shown on this device, or
  /// `null`.
  Either<Failure, String?> popupShownDay(String popupId);

  Future<Either<Failure, Unit>> savePopupShownDay(String popupId, String day);
}
