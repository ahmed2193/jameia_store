import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/home_bootstrap.dart';
import '../repositories/home_repository.dart';

class SelectDueHomePopupsParams extends Equatable {
  const SelectDueHomePopupsParams({required this.popups, required this.today});

  final List<HomeMarketingPopup> popups;

  /// The device's calendar day.
  final DateTime today;

  @override
  List<Object?> get props => [popups, today];
}

/// The marketing popups that may show now, in backend order: a `session` popup
/// always (the cubit shows the queue once per session), a `day` popup only
/// when it was not already shown on [SelectDueHomePopupsParams.today]. A
/// storage read that fails counts as "not shown": better one popup too many
/// than a campaign that never appears.
class SelectDueHomePopupsUseCase
    implements
        SyncUseCase<List<HomeMarketingPopup>, SelectDueHomePopupsParams> {
  const SelectDueHomePopupsUseCase(this._repository);

  final HomeRepository _repository;

  @override
  Either<Failure, List<HomeMarketingPopup>> call(
    SelectDueHomePopupsParams params,
  ) {
    final today = dayStamp(params.today);
    return Right([
      for (final popup in params.popups)
        if (popup.frequency == HomePopupFrequency.session ||
            _repository.popupShownDay(popup.id).getOrElse(() => null) != today)
          popup,
    ]);
  }

  /// `YYYY-MM-DD` of [date] in the device's own time zone.
  static String dayStamp(DateTime date) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}
