import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';

enum DeliveryCodeStatus { initial, loading, loaded, error }

/// State of the delivery-code screen: the saved code, the editor draft and a
/// flag that is on right after a save (until the next edit).
class DeliveryCodeState extends Equatable {
  const DeliveryCodeState({
    this.status = DeliveryCodeStatus.initial,
    this.savedCode = '',
    this.draft = '',
    this.saved = false,
    this.failure,
  });

  /// Digits in a delivery code.
  static const int codeLength = 4;

  final DeliveryCodeStatus status;

  /// The persisted delivery code.
  final String savedCode;

  /// The editor input: 0..[codeLength] ASCII digits.
  final String draft;

  /// `true` after a successful save, until the draft changes again.
  final bool saved;

  /// Transient: every [copyWith] clears it.
  final Failure? failure;

  bool get isComplete => draft.length == codeLength;

  /// Save is enabled only when the digits form a new code.
  bool get canSave => isComplete && draft != savedCode;

  DeliveryCodeState copyWith({
    DeliveryCodeStatus? status,
    String? savedCode,
    String? draft,
    bool? saved,
    Failure? failure,
  }) => DeliveryCodeState(
    status: status ?? this.status,
    savedCode: savedCode ?? this.savedCode,
    draft: draft ?? this.draft,
    saved: saved ?? this.saved,
    failure: failure,
  );

  @override
  List<Object?> get props => [status, savedCode, draft, saved, failure];
}
