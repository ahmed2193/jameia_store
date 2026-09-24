import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/jameia_address_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/address_draft.dart';
import '../../domain/entities/address_field.dart';
import '../../domain/entities/address_update.dart';

enum AddressEditStatus { editing, saving, saved }

/// Create / edit address form: the [draft] plus the save lifecycle. The field
/// rules come from `AddressDraft` (domain); widgets only read the results.
class AddressEditState extends Equatable {
  const AddressEditState({
    required this.draft,
    this.original,
    this.status = AddressEditStatus.editing,
    this.showErrors = false,
    this.saved,
    this.failure,
    this.rejected = false,
  });

  final AddressDraft draft;

  /// The address being edited; `null` while creating one.
  final JameiaAddressEntity? original;
  final AddressEditStatus status;

  /// Set by the first submit with invalid fields: inline errors show from
  /// then on.
  final bool showErrors;

  /// The server's copy once saved (the original when nothing changed).
  final JameiaAddressEntity? saved;

  /// Transient — cleared on every [copyWith]; the page toasts it.
  final Failure? failure;

  /// Transient one-shot: the last submit was blocked by invalid fields.
  final bool rejected;

  bool get isEditing => original != null;

  bool get isSaving => status == AddressEditStatus.saving;

  AddressFieldError? errorFor(AddressField field) =>
      showErrors ? draft.errorFor(field) : null;

  /// What a PATCH would send; empty while creating.
  AddressUpdate get update {
    final current = original;
    if (current == null) return const AddressUpdate();
    return AddressUpdate.diff(original: current, draft: draft);
  }

  AddressEditState copyWith({
    AddressDraft? draft,
    AddressEditStatus? status,
    bool? showErrors,
    JameiaAddressEntity? saved,
    Failure? failure,
    bool rejected = false,
  }) => AddressEditState(
    draft: draft ?? this.draft,
    original: original,
    status: status ?? this.status,
    showErrors: showErrors ?? this.showErrors,
    saved: saved ?? this.saved,
    failure: failure,
    rejected: rejected,
  );

  @override
  List<Object?> get props => [
    draft,
    original,
    status,
    showErrors,
    saved,
    failure,
    rejected,
  ];
}
