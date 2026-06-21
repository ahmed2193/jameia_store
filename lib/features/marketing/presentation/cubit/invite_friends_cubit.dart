import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/keeta_repository.dart';

/// Page-scoped state for the Invite-friends (referral) screen. Built INLINE via
/// `BlocProvider(create: (_) => InviteFriendsCubit(sl<KeetaRepository>()))` — not
/// registered in the service locator. Serves dummy referral data (code, reward
/// tiers, earned summary) and tracks the transient "copied" affordance.
class InviteFriendsCubit extends Cubit<InviteFriendsState> {
  InviteFriendsCubit(this._repo) : super(const InviteFriendsState());

  final KeetaRepository _repo;

  /// Dummy referral code derived from the signed-in user (stable, offline).
  String get referralCode {
    final id = _repo.user.id.toUpperCase().replaceAll('-', '');
    final tail = id.length >= 4 ? id.substring(id.length - 4) : id.padLeft(4, '0');
    return 'KEETA$tail';
  }

  /// Per-referral reward shown in the hero headline + step list (dummy KD value).
  double get rewardPerFriend => 2.000;

  /// Aggregate earned summary (dummy): friends joined + total KD earned.
  int get friendsJoined => 7;
  double get totalEarned => 14.000;
  double get pendingEarned => 4.000;

  void markCopied() {
    emit(state.copyWith(copied: true));
  }

  void resetCopied() {
    if (state.copied) emit(state.copyWith(copied: false));
  }
}

class InviteFriendsState {
  const InviteFriendsState({this.copied = false});

  final bool copied;

  InviteFriendsState copyWith({bool? copied}) =>
      InviteFriendsState(copied: copied ?? this.copied);
}
