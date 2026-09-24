import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// One row of `GET /v1/account/loyalty` → `data`:
/// `{ _id, customerId, type, pointsDelta (signed), referenceId, createdAt,
/// expiresAt? }`.
class LoyaltyEntryModel {
  const LoyaltyEntryModel({
    required this.id,
    required this.type,
    required this.pointsDelta,
    required this.createdAt,
    this.expiresAt,
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String typeKey = 'type';
  static const String pointsDeltaKey = 'pointsDelta';
  static const String createdAtKey = 'createdAt';
  static const String expiresAtKey = 'expiresAt';

  /// Throws [ParsingException] without an id or a readable `createdAt`.
  factory LoyaltyEntryModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('points entry: id missing');
    final createdAt = JsonRead.dateTime(json[createdAtKey]);
    if (createdAt == null) {
      throw const ParsingException('points entry: bad createdAt');
    }
    return LoyaltyEntryModel(
      id: id,
      type: JsonRead.string(json[typeKey]) ?? '',
      pointsDelta: JsonRead.integer(json[pointsDeltaKey]) ?? 0,
      createdAt: createdAt,
      expiresAt: JsonRead.dateTime(json[expiresAtKey]),
    );
  }

  final String id;

  /// Wire value; the mapper turns it into the enum.
  final String type;

  /// Signed.
  final int pointsDelta;
  final DateTime createdAt;
  final DateTime? expiresAt;
}
