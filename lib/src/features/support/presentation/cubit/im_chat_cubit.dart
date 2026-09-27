import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_active_rider_name_usecase.dart';
import 'im_chat_state.dart';

export 'im_chat_state.dart';

/// Page-scoped cubit of the rider chat; the page calls [load]. The chat keeps
/// the fallback rider when none resolves.
class ImChatCubit extends Cubit<ImChatState> with SafeCubitMixin<ImChatState> {
  ImChatCubit(this._getActiveRiderName) : super(const ImChatState());

  final GetActiveRiderNameUseCase _getActiveRiderName;

  Future<void> load() async {
    final result = await _getActiveRiderName(const NoParams());
    result.fold((_) {}, (name) {
      if (name != null) safeEmit(state.copyWith(riderName: name));
    });
  }
}
