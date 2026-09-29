import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/text/ascii_digits.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_delivery_code_usecase.dart';
import 'delivery_code_state.dart';

export 'delivery_code_state.dart';

/// Page-scoped cubit of the delivery-code screen: loads the saved code on
/// creation through [GetDeliveryCodeUseCase]. Save is local only (the code
/// comes from the offline catalogue, which is read-only).
class DeliveryCodeCubit extends Cubit<DeliveryCodeState>
    with SafeCubitMixin<DeliveryCodeState> {
  DeliveryCodeCubit(this._getDeliveryCode) : super(const DeliveryCodeState()) {
    load();
  }

  final GetDeliveryCodeUseCase _getDeliveryCode;

  Future<void> load() async {
    safeEmit(state.copyWith(status: DeliveryCodeStatus.loading));
    final result = await _getDeliveryCode(const NoParams());
    result.fold(
      (failure) => safeEmit(
        state.copyWith(status: DeliveryCodeStatus.error, failure: failure),
      ),
      (code) => safeEmit(
        state.copyWith(
          status: DeliveryCodeStatus.loaded,
          savedCode: code,
          draft: code,
        ),
      ),
    );
  }

  /// Keeps the digits of [value] (ASCII, Arabic-Indic or Persian) as ASCII,
  /// up to [DeliveryCodeState.codeLength].
  void edit(String value) {
    final digits = StringBuffer();
    for (final rune in value.runes) {
      final digit = asciiDigitUnit(rune);
      if (digit == null) continue;
      digits.writeCharCode(digit);
      if (digits.length == DeliveryCodeState.codeLength) break;
    }
    final draft = digits.toString();
    if (draft == state.draft) return;
    safeEmit(state.copyWith(draft: draft, saved: false));
  }

  /// Stores the new code locally and raises [DeliveryCodeState.saved].
  void save() {
    if (!state.canSave) return;
    safeEmit(
      state.copyWith(
        savedCode: state.draft,
        saved: true,
        savedRevision: state.savedRevision + 1,
      ),
    );
  }
}
