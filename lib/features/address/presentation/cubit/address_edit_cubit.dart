import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';

/// Rider hand-over preference (KeeTa "when can't reach you" / drop-off options).
enum DropOff { handToMe, leaveAtDoor }

/// Immutable form state for the address create / edit screen. Text fields are
/// held by the screen's controllers; the cubit owns the discrete choices
/// (label, drop-off) plus a pinned-location snapshot used for the summary card
/// and the Save gate.
class AddressEditState extends Equatable {
  const AddressEditState({
    required this.id,
    required this.label,
    required this.dropOff,
    required this.poi,
    required this.line,
    required this.area,
    required this.building,
    required this.door,
    required this.floor,
    required this.recipient,
    required this.phone,
    required this.note,
    required this.lat,
    required this.lng,
    required this.isDefault,
  });

  final String? id; // null when creating a new address
  final String label; // Home | Office | Other
  final DropOff dropOff;
  final String poi;
  final String line;
  final String area;
  final String building;
  final String door;
  final String floor;
  final String recipient;
  final String phone;
  final String note;
  final double lat;
  final double lng;
  final bool isDefault;

  /// The Save CTA is enabled once a label is chosen and the location is pinned.
  bool get canSave =>
      label.isNotEmpty && (poi.trim().isNotEmpty || line.trim().isNotEmpty);

  AddressEditState copyWith({
    String? label,
    DropOff? dropOff,
    String? poi,
  }) {
    return AddressEditState(
      id: id,
      label: label ?? this.label,
      dropOff: dropOff ?? this.dropOff,
      poi: poi ?? this.poi,
      line: line,
      area: area,
      building: building,
      door: door,
      floor: floor,
      recipient: recipient,
      phone: phone,
      note: note,
      lat: lat,
      lng: lng,
      isDefault: isDefault,
    );
  }

  @override
  List<Object?> get props =>
      [id, label, dropOff, poi, line, area, isDefault];
}

/// Drives the address create / edit form. Constructed inline by the screen with
/// `sl<KeetaRepository>()`; not registered in the service locator.
class AddressEditCubit extends Cubit<AddressEditState> {
  AddressEditCubit(this._repo, {KeetaAddress? initial})
      : super(_seed(initial));

  // ignore: unused_field — kept for parity with sibling cubits / future POI lookups.
  final KeetaRepository _repo;

  static AddressEditState _seed(KeetaAddress? a) {
    return AddressEditState(
      id: a?.id,
      label: a?.label ?? 'Home',
      dropOff: DropOff.handToMe,
      poi: a?.area ?? '',
      line: a?.line ?? '',
      area: a?.area ?? '',
      building: '',
      door: '',
      floor: '',
      recipient: a?.recipient ?? '',
      phone: a?.phone ?? '',
      note: '',
      lat: a?.lat ?? 0,
      lng: a?.lng ?? 0,
      isDefault: a?.isDefault ?? false,
    );
  }

  void setLabel(String label) => emit(state.copyWith(label: label));

  void setDropOff(DropOff dropOff) => emit(state.copyWith(dropOff: dropOff));

  void setPoi(String poi) => emit(state.copyWith(poi: poi));

  /// Builds the [KeetaAddress] to hand back to the caller (the saved-address
  /// list / checkout). No network in the offline clone — the screen pops it.
  KeetaAddress save({
    required String poi,
    required String building,
    required String door,
    required String floor,
    required String recipient,
    required String phone,
    required String note,
  }) {
    final s = state;
    final detail = [building, door, floor]
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join(', ');
    final base = poi.trim().isNotEmpty ? poi.trim() : s.line;
    final line = detail.isEmpty ? base : '$base ($detail)';
    return KeetaAddress(
      id: s.id ?? 'addr_${DateTime.now().millisecondsSinceEpoch}',
      label: s.label,
      line: line,
      area: poi.trim().isNotEmpty ? poi.trim() : s.area,
      recipient: recipient.trim(),
      phone: phone.trim(),
      isDefault: s.isDefault,
      lat: s.lat,
      lng: s.lng,
    );
  }
}
