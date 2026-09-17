import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/utils/jameia_geocode.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/repositories/address_repository.dart';

/// Re-export the address-domain enums so screens import them via the cubit.
export '../../../../core/utils/jameia_geocode.dart'
    show StructType, LabelType, DropOff, AddrField;

/// Validation failure key (i18n) returned by [AddressEditCubit.validate].
enum AddressValidation {
  ok,
  infoIncomplete, // address_addresspage_infoincompletetoast
  phoneInvalid, // address_addresspage_phonenumberverificationtoast
  altRequired, // leave-at-spot needs an alt location
}

/// Lifecycle of the create / edit form: [editing] while the user fills it in,
/// [saving] during the persist round-trip, then [saved] / [error].
enum AddressEditStatus { editing, saving, saved, error }

/// Immutable state for the unified address create / edit screen. Holds the
/// pinned location, the schema-driven field values, the tag/struct/drop-off
/// choices, and the serviceable flag — enough to drive both the SELECT (map)
/// and FORM stages plus the Save gate.
class AddressEditState extends Equatable {
  const AddressEditState({
    required this.id,
    required this.structType,
    required this.label,
    required this.dropOff,
    required this.dropSpot,
    required this.altLocation,
    required this.lat,
    required this.lng,
    required this.area,
    required this.buildingName,
    required this.aptNumber,
    required this.unitOrFloor,
    required this.companyName,
    required this.street,
    required this.block,
    required this.avenue,
    required this.additionalDirection,
    required this.recipient,
    required this.phone,
    required this.note,
    required this.isDefault,
    this.status = AddressEditStatus.editing,
    this.error,
  });

  final String? id; // null when creating
  final StructType structType; // apartment | house | office
  final LabelType label; // tag glyph (home | work | hangout | other …)
  final DropOff dropOff; // handToMe | leaveAtSpot
  final String dropSpot; // frontDoor | lobby | frontDesk | other | ''
  final String altLocation; // required when dropOff == leaveAtSpot
  final double lat;
  final double lng;
  final String area;
  final String buildingName;
  final String aptNumber;
  final String unitOrFloor;
  final String companyName;
  final String street;
  final String block;
  final String avenue;
  final String additionalDirection;
  final String recipient;
  final String phone;
  final String note;
  final bool isDefault;
  final AddressEditStatus status;
  final String? error;

  /// The schema for the active struct type.
  AddressSchema get schema => JameiaGeocode.kwSchema;

  /// Current value for a schema field (so the form can render generically).
  String fieldValue(AddrField f) {
    switch (f) {
      case AddrField.area:
        return area;
      case AddrField.buildingName:
        return buildingName;
      case AddrField.aptNumber:
        return aptNumber;
      case AddrField.unitOrFloor:
        return unitOrFloor;
      case AddrField.companyName:
        return companyName;
      case AddrField.street:
        return street;
      case AddrField.block:
        return block;
      case AddrField.avenue:
        return avenue;
      case AddrField.additionalDirection:
        return additionalDirection;
      case AddrField.recipient:
        return recipient;
      case AddrField.phone:
        return phone;
      case AddrField.note:
        return note;
    }
  }

  AddressStruct get _struct => AddressStruct(
    structType: structType,
    area: area,
    buildingName: buildingName,
    aptNumber: aptNumber,
    unitOrFloor: unitOrFloor,
    companyName: companyName,
    street: street,
    block: block,
    avenue: avenue,
    additionalDirection: additionalDirection,
  );

  /// Composed brief saved-address line.
  String get briefLine => JameiaGeocode.composeBrief(_struct);

  /// Composed detail line.
  String get detailLine => JameiaGeocode.composeDetail(_struct);

  /// All `necessary` schema fields for the active struct type are filled, the
  /// phone is non-empty, and (when leave-at-spot) the alt location is set.
  bool get canSave {
    for (final spec in JameiaGeocode.kwSchema.fieldsFor(structType)) {
      if (spec.necessary && fieldValue(spec.field).trim().isEmpty) return false;
    }
    if (phone.trim().isEmpty) return false;
    if (dropOff == DropOff.leaveAtSpot && altLocation.trim().isEmpty) {
      return false;
    }
    return true;
  }

  AddressEditState copyWith({
    StructType? structType,
    LabelType? label,
    DropOff? dropOff,
    String? dropSpot,
    String? altLocation,
    double? lat,
    double? lng,
    String? area,
    String? buildingName,
    String? aptNumber,
    String? unitOrFloor,
    String? companyName,
    String? street,
    String? block,
    String? avenue,
    String? additionalDirection,
    String? recipient,
    String? phone,
    String? note,
    bool? isDefault,
    AddressEditStatus? status,
    String? error,
  }) {
    return AddressEditState(
      id: id,
      structType: structType ?? this.structType,
      label: label ?? this.label,
      dropOff: dropOff ?? this.dropOff,
      dropSpot: dropSpot ?? this.dropSpot,
      altLocation: altLocation ?? this.altLocation,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      area: area ?? this.area,
      buildingName: buildingName ?? this.buildingName,
      aptNumber: aptNumber ?? this.aptNumber,
      unitOrFloor: unitOrFloor ?? this.unitOrFloor,
      companyName: companyName ?? this.companyName,
      street: street ?? this.street,
      block: block ?? this.block,
      avenue: avenue ?? this.avenue,
      additionalDirection: additionalDirection ?? this.additionalDirection,
      recipient: recipient ?? this.recipient,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      isDefault: isDefault ?? this.isDefault,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    id,
    structType,
    label,
    dropOff,
    dropSpot,
    altLocation,
    lat,
    lng,
    area,
    buildingName,
    aptNumber,
    unitOrFloor,
    companyName,
    street,
    block,
    avenue,
    additionalDirection,
    recipient,
    phone,
    note,
    isDefault,
    status,
    error,
  ];
}

/// Drives the unified address create / edit form. Resolved via
/// `sl<AddressEditCubit>()..seed(initialAddress)` (the screen seeds it at
/// `BlocProvider` create time); [save] persists through the [AddressRepository]
/// add / update methods (which delegate to the `JameiaRepository` address book).
class AddressEditCubit extends Cubit<AddressEditState>
    with SafeCubitMixin<AddressEditState> {
  AddressEditCubit(this._repository) : super(_seed(null));

  final AddressRepository _repository;

  /// True when editing an existing address (screen jumps straight to FORM).
  bool _editing = false;
  bool get isEditing => _editing;

  /// Seed the form for create (`initial == null`) or edit (an existing address).
  /// Called by the screen at `BlocProvider` create time, before the first build
  /// reads the state to prime its text controllers.
  void seed(JameiaAddress? initial) {
    _editing = initial != null;
    safeEmit(_seed(initial));
  }

  static AddressEditState _seed(JameiaAddress? a) {
    return AddressEditState(
      id: a?.id,
      structType: a?.structType ?? StructType.apartment,
      label: a?.labelType ?? LabelType.home,
      dropOff: a?.dropOff ?? DropOff.handToMe,
      dropSpot: a?.dropSpot ?? 'frontDoor',
      altLocation: a?.altLocation ?? '',
      lat: a?.lat ?? JameiaGeocode.base.latitude,
      lng: a?.lng ?? JameiaGeocode.base.longitude,
      area: a?.area ?? '',
      buildingName: a?.buildingName ?? '',
      aptNumber: a?.aptNumber ?? '',
      unitOrFloor: a?.unitOrFloor ?? '',
      companyName: a?.companyName ?? '',
      street: a?.street ?? '',
      block: a?.block ?? '',
      avenue: a?.avenue ?? '',
      additionalDirection: a?.additionalDirection ?? '',
      recipient: a?.recipient ?? '',
      phone: a?.phone ?? '',
      note: a?.note ?? '',
      isDefault: a?.isDefault ?? false,
    );
  }

  // ── Discrete choices ────────────────────────────────────────────────────────

  void setStructType(StructType t) => safeEmit(state.copyWith(structType: t));

  void setLabel(LabelType l) => safeEmit(state.copyWith(label: l));

  void setDropOff(DropOff d) => safeEmit(state.copyWith(dropOff: d));

  void setDropSpot(String spot) => safeEmit(state.copyWith(dropSpot: spot));

  void setDefault(bool v) => safeEmit(state.copyWith(isDefault: v));

  // ── Location ────────────────────────────────────────────────────────────────

  /// Set the confirmed pin location + resolved area (called from the SELECT
  /// stage's Confirm). Does not touch the user-entered street/block fields.
  void setLocation({
    required double lat,
    required double lng,
    required String area,
  }) {
    safeEmit(state.copyWith(lat: lat, lng: lng, area: area));
  }

  // ── Schema fields ───────────────────────────────────────────────────────────

  /// Generic schema-field setter (drives the form's text fields). `altLocation`
  /// has its own setter below.
  void setField(AddrField f, String value) {
    switch (f) {
      case AddrField.area:
        safeEmit(state.copyWith(area: value));
      case AddrField.buildingName:
        safeEmit(state.copyWith(buildingName: value));
      case AddrField.aptNumber:
        safeEmit(state.copyWith(aptNumber: value));
      case AddrField.unitOrFloor:
        safeEmit(state.copyWith(unitOrFloor: value));
      case AddrField.companyName:
        safeEmit(state.copyWith(companyName: value));
      case AddrField.street:
        safeEmit(state.copyWith(street: value));
      case AddrField.block:
        safeEmit(state.copyWith(block: value));
      case AddrField.avenue:
        safeEmit(state.copyWith(avenue: value));
      case AddrField.additionalDirection:
        safeEmit(state.copyWith(additionalDirection: value));
      case AddrField.recipient:
        safeEmit(state.copyWith(recipient: value));
      case AddrField.phone:
        safeEmit(state.copyWith(phone: value));
      case AddrField.note:
        safeEmit(state.copyWith(note: value));
    }
  }

  void setAltLocation(String value) =>
      safeEmit(state.copyWith(altLocation: value));

  // ── Validate + save ─────────────────────────────────────────────────────────

  /// Per-field validation — the SOURCE OF TRUTH for the inline form errors.
  ///
  /// Returns a map of every invalid [AddrField] → its i18n KEY (the screen
  /// resolves the message with `.tr()`). An empty map means every field is
  /// valid. The leave-at-spot alt-location is NOT an [AddrField] and is handled
  /// separately by the screen + [isValid].
  ///
  ///   • each schema field where `spec.necessary && value.trim().isEmpty`
  ///     → 'addr.field_required'
  ///   • recipient empty → 'addr.recipient_required'
  ///   • phone empty → 'addr.field_required'; else if the digits-only length
  ///     != 8 (Kuwait mobile) → 'addr.phone_format'
  Map<AddrField, String> fieldErrors() {
    final s = state;
    final errors = <AddrField, String>{};
    for (final spec in JameiaGeocode.kwSchema.fieldsFor(s.structType)) {
      if (spec.necessary && s.fieldValue(spec.field).trim().isEmpty) {
        errors[spec.field] = 'addr.field_required';
      }
    }
    if (s.recipient.trim().isEmpty) {
      errors[AddrField.recipient] = 'addr.recipient_required';
    }
    final phone = s.phone.trim();
    if (phone.isEmpty) {
      errors[AddrField.phone] = 'addr.field_required';
    } else if (phone.replaceAll(RegExp(r'[^0-9]'), '').length != 8) {
      errors[AddrField.phone] = 'addr.phone_format';
    }
    return errors;
  }

  /// True when every field passes [fieldErrors] AND (when leave-at-spot) the
  /// alt-location is set. The canonical "form is complete + valid" gate.
  bool get isValid =>
      fieldErrors().isEmpty &&
      (state.dropOff != DropOff.leaveAtSpot ||
          state.altLocation.trim().isNotEmpty);

  /// Validate all necessary fields. Returns the failure key (or [ok]).
  AddressValidation validate() {
    final s = state;
    for (final spec in JameiaGeocode.kwSchema.fieldsFor(s.structType)) {
      if (spec.necessary && s.fieldValue(spec.field).trim().isEmpty) {
        return AddressValidation.infoIncomplete;
      }
    }
    final phone = s.phone.trim();
    if (phone.isEmpty) return AddressValidation.infoIncomplete;
    if (phone.replaceAll(RegExp(r'[^0-9]'), '').length < 6) {
      return AddressValidation.phoneInvalid;
    }
    if (s.dropOff == DropOff.leaveAtSpot && s.altLocation.trim().isEmpty) {
      return AddressValidation.altRequired;
    }
    return AddressValidation.ok;
  }

  /// Compose the [JameiaAddress], persist it through the add / update use case,
  /// and return the saved row for the screen to pop with (null on failure).
  Future<JameiaAddress?> save() async {
    safeEmit(state.copyWith(status: AddressEditStatus.saving));
    // TODO(P2.9-boundary): the composed JameiaAddress is the persistence payload
    // handed to the repository and popped back to the list picker — a deliberate
    // write boundary (core DTO in/out, not an internal domain value).
    final address = _compose(state);
    final result = _editing
        ? await _repository.updateAddress(address)
        : await _repository.addAddress(address);
    return result.fold(
      (failure) {
        safeEmit(
          state.copyWith(
            status: AddressEditStatus.error,
            error: failure.message,
          ),
        );
        return null;
      },
      (saved) {
        safeEmit(state.copyWith(status: AddressEditStatus.saved));
        return saved;
      },
    );
  }

  /// Build the persisted [JameiaAddress] from the current form state.
  JameiaAddress _compose(AddressEditState s) {
    final brief = s.briefLine;
    final detail = s.detailLine;
    final id = s.id ?? 'addr_${DateTime.now().millisecondsSinceEpoch}';
    return JameiaAddress(
      id: id,
      label: _labelDisplay(s.label),
      line: brief.isNotEmpty ? brief : s.area,
      area: s.area,
      recipient: s.recipient.trim(),
      phone: s.phone.trim(),
      isDefault: s.isDefault,
      lat: s.lat,
      lng: s.lng,
      structType: s.structType,
      labelType: s.label,
      dropOff: s.dropOff,
      dropSpot: s.dropOff == DropOff.leaveAtSpot ? s.dropSpot : '',
      altLocation: s.dropOff == DropOff.leaveAtSpot ? s.altLocation.trim() : '',
      poiName: brief,
      brief: brief,
      detail: detail,
      buildingName: s.buildingName.trim(),
      aptNumber: s.aptNumber.trim(),
      unitOrFloor: s.unitOrFloor.trim(),
      companyName: s.companyName.trim(),
      street: s.street.trim(),
      block: s.block.trim(),
      avenue: s.avenue.trim(),
      additionalDirection: s.additionalDirection.trim(),
      note: s.note.trim(),
    );
  }

  static String _labelDisplay(LabelType l) {
    switch (l) {
      case LabelType.home:
        return 'Home';
      case LabelType.work:
        return 'Work';
      case LabelType.hangout:
        return 'Hangout';
      case LabelType.faceDelivery:
      case LabelType.assignedPlace:
      case LabelType.other:
        return 'Other';
    }
  }
}
