import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/domain/entities/pro_membership_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/pro_membership.dart';

enum ProMembershipStatus { initial, loading, loaded, error }

/// What the customer just did, reported once so the page can toast it and
/// refresh the app-global customer snapshot (`isPro`).
enum ProMembershipOutcome { subscribed, cancelled }

class ProMembershipState extends Equatable {
  const ProMembershipState({
    this.status = ProMembershipStatus.initial,
    this.program = ProProgram.empty,
    this.subscription,
    this.isSignedOut = false,
    this.selectedPlanId,
    this.submittingPlanId,
    this.isCancelling = false,
    this.programFreshness = DataFreshness.none,
    this.subscriptionFreshness = DataFreshness.none,
    this.failure,
    this.actionFailed = false,
    this.outcome,
  });

  final ProMembershipStatus status;
  final ProProgram program;

  /// `null` = none (or a guest, see [isSignedOut]).
  final ProSubscription? subscription;

  /// The subscription route answered 401: plans stay visible, subscribing
  /// leads to sign-in.
  final bool isSignedOut;

  /// The plan the tabs show and the CTA subscribes to (see
  /// [ProProgram.initialPlan]); survives a reload while the plan still exists.
  final String? selectedPlanId;

  /// The plan whose "subscribe" is in flight (its button shows the loader,
  /// every other action is disabled).
  final String? submittingPlanId;
  final bool isCancelling;

  /// How fresh [program] is: [DataFreshness.none] until one arrives (the
  /// device copy counts).
  final DataFreshness programFreshness;

  /// How fresh [subscription] is: [DataFreshness.none] until it arrives (the
  /// device copy counts), and for a guest.
  final DataFreshness subscriptionFreshness;

  /// Transient with [ProMembershipStatus.loaded] (cleared on the next
  /// [copyWith]; the page localizes it); with [ProMembershipStatus.error] the
  /// reason for the full-screen state, kept while the status stays `error`.
  final Failure? failure;

  /// Transient — [failure] answers the customer's subscribe / cancel, not a
  /// reload.
  final bool actionFailed;

  /// Transient — cleared on every [copyWith].
  final ProMembershipOutcome? outcome;

  bool get isLoaded => status == ProMembershipStatus.loaded;
  bool get isBusy => submittingPlanId != null || isCancelling;

  /// A programme has arrived (the device copy counts).
  bool get knowsProgram => programFreshness.fetchedAt != null;

  /// Where the customer stands is known: their subscription (or none) has
  /// arrived — the device copy counts — or they are a guest.
  bool get knowsMembership =>
      isSignedOut || subscriptionFreshness.fetchedAt != null;

  /// The membership on screen is the server's answer (a read, a subscribe,
  /// a cancel), not the device copy: only that is handed to the app-global
  /// Pro status.
  bool get isMembershipConfirmed =>
      subscriptionFreshness.fetchedAt != null &&
      !subscriptionFreshness.fromCache;

  /// The page's "Updated … ago" and its reconnect refresh: stale when the
  /// programme or the subscription is, dated by the older.
  DataFreshness get freshness =>
      programFreshness.alongside(subscriptionFreshness);

  /// Has the Pro perks right now (see [ProSubscription.hasBenefits]): no
  /// join button, the membership card instead.
  bool get isMember => subscription?.hasBenefits ?? false;

  /// Where the customer stands (see [ProSubscription.membership]) — what
  /// the page reports to the app-global Pro status once loaded.
  ProMembershipEntity get membership => isSignedOut
      ? ProMembershipEntity.guest
      : subscription?.membership ?? ProMembershipEntity.prospect;

  /// Had Pro, and it ran out: the page greets them back and says "rejoin".
  bool get isLapsed => membership.standing == ProStanding.lapsed;

  ProPlan? get selectedPlan => program.planById(selectedPlanId);

  /// The "Save N%" chip of every plan tab, in plan order (0 = no chip): the
  /// programme's [ProProgram.badgeSavings], none at all for a member (there
  /// is nothing left to sell them).
  List<int> get planSavings => isMember
      ? List<int>.filled(program.plans.length, 0)
      : program.badgeSavings;

  ProMembershipState copyWith({
    ProMembershipStatus? status,
    ProProgram? program,
    ProSubscription? subscription,
    bool clearSubscription = false,
    bool? isSignedOut,
    String? selectedPlanId,
    bool clearSelectedPlan = false,
    String? submittingPlanId,
    bool clearSubmitting = false,
    bool? isCancelling,
    DataFreshness? programFreshness,
    DataFreshness? subscriptionFreshness,
    Failure? failure,
    bool actionFailed = false,
    ProMembershipOutcome? outcome,
  }) {
    final nextStatus = status ?? this.status;
    return ProMembershipState(
      status: nextStatus,
      program: program ?? this.program,
      subscription: clearSubscription
          ? null
          : subscription ?? this.subscription,
      isSignedOut: isSignedOut ?? this.isSignedOut,
      selectedPlanId: clearSelectedPlan
          ? null
          : selectedPlanId ?? this.selectedPlanId,
      submittingPlanId: clearSubmitting
          ? null
          : submittingPlanId ?? this.submittingPlanId,
      isCancelling: isCancelling ?? this.isCancelling,
      programFreshness: programFreshness ?? this.programFreshness,
      subscriptionFreshness:
          subscriptionFreshness ?? this.subscriptionFreshness,
      failure:
          failure ??
          (nextStatus == ProMembershipStatus.error ? this.failure : null),
      actionFailed: actionFailed,
      outcome: outcome,
    );
  }

  @override
  List<Object?> get props => [
    status,
    program,
    subscription,
    isSignedOut,
    selectedPlanId,
    submittingPlanId,
    isCancelling,
    programFreshness,
    subscriptionFreshness,
    failure,
    actionFailed,
    outcome,
  ];
}
