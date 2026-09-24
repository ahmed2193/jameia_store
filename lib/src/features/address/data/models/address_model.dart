import 'dart:developer';

import '../../../../core/error/exceptions.dart';

/// One saved address as `/v1/account/addresses` sends it (list row, and the
/// `address` of a POST / PATCH reply):
///
/// ```json
/// { "_id": "…", "label": "Home", "city": "Salmiya", "governorateNo": "…",
///   "areaId": "…", "block": "7", "street": "22", "building": "5",
///   "floor": "2", "apartment": "12", "phone": "+96550001122",
///   "notes": "…", "lat": 29.33, "lng": 48.07, "isDefault": true }
/// ```
///
/// Only `_id` is mandatory here (tolerates `id`), and it must be a Mongo
/// ObjectId (24 hex chars, the spec pattern) because it goes into request
/// paths. Every other field falls back to empty / `false`. [toJson] writes the
/// same keys back, so the device cache holds exactly the API rows.
class AddressModel {
  const AddressModel({
    required this.id,
    this.label = '',
    this.city = '',
    this.governorateNo = '',
    this.areaId = '',
    this.block = '',
    this.street = '',
    this.building = '',
    this.floor = '',
    this.apartment = '',
    this.phone = '',
    this.notes = '',
    this.lat,
    this.lng,
    this.isDefault = false,
  });

  static const String idKey = '_id';
  static const String altIdKey = 'id';
  static const String labelKey = 'label';
  static const String cityKey = 'city';
  static const String governorateNoKey = 'governorateNo';
  static const String areaIdKey = 'areaId';
  static const String blockKey = 'block';
  static const String streetKey = 'street';
  static const String buildingKey = 'building';
  static const String floorKey = 'floor';
  static const String apartmentKey = 'apartment';
  static const String phoneKey = 'phone';
  static const String notesKey = 'notes';
  static const String latKey = 'lat';
  static const String lngKey = 'lng';
  static const String isDefaultKey = 'isDefault';

  static final RegExp _objectId = RegExp(r'^[0-9a-fA-F]{24}$');

  /// Whether [id] can safely name an address in a request path.
  static bool isObjectId(String id) => _objectId.hasMatch(id);

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    final id = json[idKey] ?? json[altIdKey];
    if (id is! String || !isObjectId(id)) {
      throw ParsingException('address: bad id $id');
    }
    return AddressModel(
      id: id,
      label: _text(json[labelKey]),
      city: _text(json[cityKey]),
      governorateNo: _text(json[governorateNoKey]),
      areaId: _text(json[areaIdKey]),
      block: _text(json[blockKey]),
      street: _text(json[streetKey]),
      building: _text(json[buildingKey]),
      floor: _text(json[floorKey]),
      apartment: _text(json[apartmentKey]),
      phone: _text(json[phoneKey]),
      notes: _text(json[notesKey]),
      lat: _number(json[latKey]),
      lng: _number(json[lngKey]),
      isDefault: json[isDefaultKey] == true,
    );
  }

  /// The rows of a list payload. A malformed row is logged and skipped, so
  /// one bad address never blanks the whole book.
  static List<AddressModel> listFromJson(List<Object?> rows) => [
    for (final row in rows) ...?_tryParse(row),
  ];

  final String id;
  final String label;
  final String city;
  final String governorateNo;
  final String areaId;
  final String block;
  final String street;
  final String building;
  final String floor;
  final String apartment;
  final String phone;
  final String notes;
  final double? lat;
  final double? lng;
  final bool isDefault;

  Map<String, dynamic> toJson() => <String, dynamic>{
    idKey: id,
    labelKey: label,
    if (city.isNotEmpty) cityKey: city,
    if (governorateNo.isNotEmpty) governorateNoKey: governorateNo,
    if (areaId.isNotEmpty) areaIdKey: areaId,
    if (block.isNotEmpty) blockKey: block,
    if (street.isNotEmpty) streetKey: street,
    if (building.isNotEmpty) buildingKey: building,
    if (floor.isNotEmpty) floorKey: floor,
    if (apartment.isNotEmpty) apartmentKey: apartment,
    if (phone.isNotEmpty) phoneKey: phone,
    if (notes.isNotEmpty) notesKey: notes,
    latKey: ?lat,
    lngKey: ?lng,
    isDefaultKey: isDefault,
  };

  static List<AddressModel>? _tryParse(Object? row) {
    if (row is! Map) return null;
    try {
      return [AddressModel.fromJson(row.cast<String, dynamic>())];
    } on AppException catch (error) {
      log('dropped address row: $error', name: 'AddressModel');
      return null;
    }
  }

  /// Text fields may arrive as numbers (`block: 7`).
  static String _text(Object? value) => switch (value) {
    String() => value,
    num() => value.toString(),
    _ => '',
  };

  static double? _number(Object? value) => switch (value) {
    num() => value.toDouble(),
    String() => double.tryParse(value),
    _ => null,
  };
}
