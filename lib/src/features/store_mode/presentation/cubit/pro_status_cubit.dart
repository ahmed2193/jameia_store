import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';
import '../../../../core/domain/entities/pro_membership_entity.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/usecases/get_pro_membership_usecase.dart';
import '../../domain/usecases/get_pro_program_usecase.dart';
import 'pro_status_state.dart';

/// App-global Pro status (provided above `MaterialApp.router`), what every
/// Pro surface outside the Pro page reads — the member badge in the home
/// header, the home banner, the Mine row, the cart nudge:
///
///   * [start] when the session is signed in (launch restore, OTP) or the
///     customer record changed — shows what the record says at once, then
///     asks the subscription route whether the membership renews, ends or
///     lapsed;
///   * [stop] on sign-out — a guest;
///   * [apply] from the Pro page, which just loaded, subscribed or cancelled
///     and knows the fresher answer;
///   * [refresh] asks the subscription route again. It runs by itself
///     [expiryGrace] after a member's paid period ends — the backend renews
///     or ends the membership then — so perks never outlive it on screen;
///   * [onReconnected] when the connection comes back — whatever the
///     network could not answer meanwhile is asked again.
///
/// The programme (what Pro includes) is public: it is read once per run,
/// with the first session answer, and again with a later one if that read
/// failed.
class ProStatusCubit extends Cubit<ProStatusState>
    with SafeCubitMixin<ProStatusState> {
  ProStatusCubit(
    this._getMembership,
    this._getProgram, {
    this._now = DateTime.now,
    this.expiryGrace = defaultExpiryGrace,
  }) : super(const ProStatusState());

  static const String _logName = 'ProStatusCubit';

  /// Leaves the backend a moment to renew or end the membership.
  static const Duration defaultExpiryGrace = Duration(minutes: 1);

  final GetProMembershipUseCase _getMembership;
  final GetProProgramUseCase _getProgram;
  final DateTime Function() _now;

  /// How long after the paid period ends the status asks again.
  final Duration expiryGrace;

  /// Bumped by every session change, [apply] and [refresh]: a subscription
  /// read that started before one answers for a session or a membership that
  /// is gone, so its reply is dropped.
  int _generation = 0;
  bool _programLoading = false;

  /// Fires [refresh] once a member's paid period is over.
  Timer? _periodEnd;

  /// Signed in. [customer] is the session's record of the customer (`null`
  /// while signed in offline with nothing saved — the standing stays unknown
  /// until the subscription route answers).
  Future<void> start(AuthCustomerEntity? customer) async {
    final generation = ++_generation;
    if (customer == null) {
      // Signed in, but nothing says whether the customer is a member yet:
      // no longer a guest, not settled either.
      if (state.membership.isGuest) {
        safeEmit(
          state.copyWith(
            membership: ProMembershipEntity.prospect,
            isSettled: false,
            isConfirmed: false,
          ),
        );
      }
    } else {
      final record = ProMembershipEntity.ofCustomer(customer);
      final current = state.membership;
      // A confirmed answer that agrees on the perks knows more than the
      // record (ending vs renewing, the plan): it stays.
      final agrees =
          state.isConfirmed &&
          !current.isGuest &&
          current.hasBenefits == record.hasBenefits;
      if (!agrees) {
        safeEmit(
          state.copyWith(
            membership: record,
            isSettled: true,
            isConfirmed: false,
          ),
        );
      }
    }
    unawaited(_loadProgram());
    await _read(generation);
  }

  /// Signed out (or no session at launch): a guest.
  void stop() {
    _generation++;
    _cancelPeriodEnd();
    safeEmit(
      state.copyWith(
        membership: ProMembershipEntity.guest,
        isSettled: true,
        isConfirmed: false,
      ),
    );
    unawaited(_loadProgram());
  }

  /// The Pro page's fresh answer (its load, a subscribe, a cancel). Ignored
  /// for a guest: a reply that lands after sign-out belongs to no one.
  void apply(ProMembershipEntity membership) {
    if (state.membership.isGuest || membership.isGuest) return;
    _generation++;
    _settle(membership);
  }

  /// Asks the subscription route again; what is on screen stays until it
  /// answers. Nothing to ask for a guest.
  Future<void> refresh() async {
    if (state.membership.isGuest) return;
    await _read(++_generation);
  }

  /// The connection came back: a programme that could not be read is read
  /// now, and a signed-in standing the server has not confirmed is asked
  /// again (what is on screen stays until it answers).
  Future<void> onReconnected() async {
    unawaited(_loadProgram());
    if (state.isConfirmed) return;
    await refresh();
  }

  Future<void> _read(int generation) async {
    final result = await _getMembership(const NoParams());
    if (generation != _generation) return;
    result.fold(
      // The standing on screen stays; the Pro page and the next session
      // change ask again.
      (failure) => log('membership unknown', name: _logName, error: failure),
      _settle,
    );
  }

  void _settle(ProMembershipEntity membership) {
    safeEmit(
      state.copyWith(
        membership: membership,
        isSettled: true,
        isConfirmed: true,
      ),
    );
    _watchPeriodEnd(membership);
  }

  /// A member's perks end with the paid period (a renewal moves it): ask
  /// again then. A period already over is left to the next launch — the
  /// backend has not moved it yet, and asking again at once would repeat.
  void _watchPeriodEnd(ProMembershipEntity membership) {
    _cancelPeriodEnd();
    final end = membership.periodEnd;
    if (!membership.hasBenefits || end == null) return;
    final left = end.difference(_now());
    if (left.isNegative) return;
    _periodEnd = Timer(left + expiryGrace, () {
      _periodEnd = null;
      unawaited(refresh());
    });
  }

  void _cancelPeriodEnd() {
    _periodEnd?.cancel();
    _periodEnd = null;
  }

  Future<void> _loadProgram() async {
    if (state.isProgramLoaded || _programLoading) return;
    _programLoading = true;
    final result = await _getProgram(const NoParams());
    _programLoading = false;
    result.fold(
      (failure) => log('programme unknown', name: _logName, error: failure),
      (program) =>
          safeEmit(state.copyWith(program: program, isProgramLoaded: true)),
    );
  }

  @override
  Future<void> close() {
    _cancelPeriodEnd();
    return super.close();
  }
}
