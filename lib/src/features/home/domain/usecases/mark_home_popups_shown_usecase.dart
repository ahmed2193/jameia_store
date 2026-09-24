import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/home_bootstrap.dart';
import '../repositories/home_repository.dart';
import 'select_due_home_popups_usecase.dart';

class MarkHomePopupsShownParams extends Equatable {
  const MarkHomePopupsShownParams({required this.popups, required this.today});

  final List<HomeMarketingPopup> popups;
  final DateTime today;

  @override
  List<Object?> get props => [popups, today];
}

/// Stamps every once-a-day popup of the queue that was just shown, so it stays
/// quiet for the rest of [MarkHomePopupsShownParams.today]. `session` popups
/// need no stamp.
class MarkHomePopupsShownUseCase
    implements UseCase<Unit, MarkHomePopupsShownParams> {
  const MarkHomePopupsShownUseCase(this._repository);

  final HomeRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(MarkHomePopupsShownParams params) async {
    final day = SelectDueHomePopupsUseCase.dayStamp(params.today);
    Failure? firstFailure;
    for (final popup in params.popups) {
      if (popup.frequency != HomePopupFrequency.day) continue;
      final result = await _repository.savePopupShownDay(popup.id, day);
      firstFailure ??= result.fold((failure) => failure, (_) => null);
    }
    return firstFailure == null ? const Right(unit) : Left(firstFailure);
  }
}
