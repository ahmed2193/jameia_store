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
  bool get isMember => subscription?.isActive ?? false;

  ProMembershipState copyWith({
    ProMembershipStatus? status,
    ProProgram? program,
    ProSubscription? subscription,
    bool clearSubscription = false,
    bool? isSignedOut,
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
    submittingPlanId,
    isCancelling,
    failure,
    outcome,
  ];
}
