import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// One row of `GET /v1/account/wallet` → `data`:
/// `{ _id, customerId, type, amount (fils, signed), referenceId, note?,
/// createdAt }`.
class WalletEntryModel {
  const WalletEntryModel({
    required this.id,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.note = '',
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String typeKey = 'type';
  static const String amountKey = 'amount';
  static const String noteKey = 'note';
  static const String createdAtKey = 'createdAt';

  /// Throws [ParsingException] without an id or a readable `createdAt`.
  factory WalletEntryModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('wallet entry: id missing');
    final createdAt = JsonRead.dateTime(json[createdAtKey]);
    if (createdAt == null) {
      throw const ParsingException('wallet entry: bad createdAt');
    }
    return WalletEntryModel(
      id: id,
      type: JsonRead.string(json[typeKey]) ?? '',
      amount: JsonRead.integer(json[amountKey]) ?? 0,
      createdAt: createdAt,
      note: JsonRead.string(json[noteKey]) ?? '',
    );
  }

  final String id;

  /// Wire value; the mapper turns it into the enum.
  final String type;

  /// Fils, signed.
  final int amount;
  final DateTime createdAt;
  final String note;
}
