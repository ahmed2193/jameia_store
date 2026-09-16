import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/rider_entity.dart';
import '../../domain/repositories/support_repository.dart';

/// State for the IM rider-chat screen (`im_user_rider_chat`) — just the resolved
/// rider identity. The message thread + composer are transient view concerns kept
/// local in the screen (per the StatefulWidget contract), so they stay out of the
/// cubit.
class ImChatState extends Equatable {
  const ImChatState({required this.rider});

  /// Rider shown in the chat app bar. Starts on a generic fallback until the
  /// repository resolves the first active order's rider.
  final RiderEntity rider;

  ImChatState copyWith({RiderEntity? rider}) =>
      ImChatState(rider: rider ?? this.rider);

  @override
  List<Object?> get props => [rider];
}

/// Page-scoped cubit — resolved via `sl<ImChatCubit>()`; resolves the active
/// rider on construction through the [SupportRepository] (the read that used to
/// reach into `core/data/keeta_repository.dart` from the chat screen now lives in
/// the data layer).
class ImChatCubit extends Cubit<ImChatState>
    with SafeCubitMixin<ImChatState> {
  ImChatCubit(this._repository) : super(_fallback) {
    load();
  }

  final SupportRepository _repository;

  /// Generic rider so the chat always renders, even before load completes / when
  /// no live order exists.
  static const ImChatState _fallback = ImChatState(
    rider: RiderEntity(name: 'Rider', phone: '', vehicle: 'motorbike'),
  );

  Future<void> load() async {
    final result = await _repository.getActiveRider();
    result.fold(
      (_) {}, // keep the fallback rider on failure
      (rider) => safeEmit(state.copyWith(rider: rider)),
    );
  }
}
