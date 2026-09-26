import 'package:equatable/equatable.dart';

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
    this.failure,
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

  /// Transient — cleared on every [copyWith]; the page localizes it.
  final Failure? failure;

  /// Transient — cleared on every [copyWith].
  final ProMembershipOutcome? outcome;

  bool get isLoaded => status == ProMembershipStatus.loaded;
  bool get isBusy => submittingPlanId != null || isCancelling;

  /// Has the Pro perks right now (see [ProSubscription.hasBenefits]): no
  /// join button, the membership card instead.
  bool get isMember => subscription?.hasBenefits ?? false;

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
    Failure? failure,
    ProMembershipOutcome? outcome,
  }) => ProMembershipState(
    status: status ?? this.status,
    program: program ?? this.program,
    subscription: clearSubscription ? null : subscription ?? this.subscription,
    isSignedOut: isSignedOut ?? this.isSignedOut,
    selectedPlanId: clearSelectedPlan
        ? null
        : selectedPlanId ?? this.selectedPlanId,
    submittingPlanId: clearSubmitting
        ? null
        : submittingPlanId ?? this.submittingPlanId,
    isCancelling: isCancelling ?? this.isCancelling,
    failure: failure,
    outcome: outcome,
  );

  @override
  List<Object?> get props => [
    status,
    program,
    subscription,
    isSignedOut,
    selectedPlanId,
    submittingPlanId,
    isCancelling,
    failure,
    outcome,
  ];
}
