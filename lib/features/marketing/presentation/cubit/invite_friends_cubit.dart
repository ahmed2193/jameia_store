import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/invite_friends.dart';
import '../../domain/repositories/marketing_repository.dart';

enum InviteFriendsStatus { initial, loading, loaded, error }

/// State for the Invite-friends (referral) screen (`mkt_invite_main`).
///
/// Loading → loaded/error. The referral snapshot (code, reward tiers, earned
/// summary) is loaded through the [MarketingRepository]; [copied] tracks the
/// transient "copied" affordance on the code box / share CTA.
class InviteFriendsState extends Equatable {
  const InviteFriendsState({
    this.status = InviteFriendsStatus.initial,
    this.invite,
    this.copied = false,
    this.error,
  });

  final InviteFriendsStatus status;

  /// Resolved referral snapshot; null until [InviteFriendsStatus.loaded].
  final InviteFriends? invite;

  /// Transient "copied" affordance state on the code box / share CTA.
  final bool copied;
  final String? error;

  InviteFriendsState copyWith({
    InviteFriendsStatus? status,
    InviteFriends? invite,
    bool? copied,
    String? error,
  }) =>
      InviteFriendsState(
        status: status ?? this.status,
        invite: invite ?? this.invite,
        copied: copied ?? this.copied,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [status, invite, copied, error];
}

/// Page-scoped cubit for the invite-friends referral screen.
///
/// Resolved via `sl<InviteFriendsCubit>()`; loads the referral snapshot on
/// construction directly from the [MarketingRepository] (dummy backend), so the
/// screen renders from state.
class InviteFriendsCubit extends Cubit<InviteFriendsState>
    with SafeCubitMixin<InviteFriendsState> {
  InviteFriendsCubit(this._repository)
      : super(const InviteFriendsState()) {
    load();
  }

  final MarketingRepository _repository;

  /// Fetch the referral snapshot. Emits loading → loaded/error; safe to call
  /// again from the error-state retry button.
  Future<void> load() async {
    safeEmit(state.copyWith(status: InviteFriendsStatus.loading));
    final result = await _repository.getInviteFriends();
    result.fold(
      (failure) => safeEmit(state.copyWith(
        status: InviteFriendsStatus.error,
        error: failure.message,
      )),
      (invite) => safeEmit(state.copyWith(
        status: InviteFriendsStatus.loaded,
        invite: invite,
      )),
    );
  }

  void markCopied() {
    safeEmit(state.copyWith(copied: true));
  }

  void resetCopied() {
    if (state.copied) safeEmit(state.copyWith(copied: false));
  }
}
