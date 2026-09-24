import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/loyalty_program.dart';
import '../../domain/usecases/get_loyalty_program_usecase.dart';

/// The store's loyalty programme for the screen that shows it (the points
/// history rules, the profile bonus hint). Secondary information: when it
/// cannot be loaded the screen simply shows none of it.
class LoyaltyProgramCubit extends Cubit<LoyaltyProgram>
    with SafeCubitMixin<LoyaltyProgram> {
  LoyaltyProgramCubit(this._getProgram) : super(LoyaltyProgram.none);

  static const String _logName = 'LoyaltyProgramCubit';

  final GetLoyaltyProgramUseCase _getProgram;

  Future<void> load() async {
    final result = await _getProgram(const NoParams());
    result.fold(
      (failure) => log('programme unavailable', name: _logName, error: failure),
      safeEmit,
    );
  }
}
