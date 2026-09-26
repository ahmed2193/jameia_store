import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// The `order` of an `order` / `order_status` block: `{ _id, orderNumber,
/// status, total, createdAt, itemCount, thumbnails[] }` — a summary, not the
/// `GET /v1/orders/{id}` shape.
class AssistantOrderSummaryModel {
  const AssistantOrderSummaryModel({
    required this.id,
    this.orderNumber = '',
    this.status = '',
    this.total = 0,
    this.createdAt,
    this.itemCount = 0,
    this.thumbnails = const <String>[],
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String orderNumberKey = 'orderNumber';
  static const String statusKey = 'status';
  static const String totalKey = 'total';
  static const String createdAtKey = 'createdAt';
  static const String itemCountKey = 'itemCount';
  static const String thumbnailsKey = 'thumbnails';

  final String id;
  final String orderNumber;
  final String status;
  final int total;
  final DateTime? createdAt;
  final int itemCount;
  final List<String> thumbnails;

  /// Throws [ParsingException] without an id: tracking opens by `_id`.
  factory AssistantOrderSummaryModel.fromJson(Map<String, dynamic> json) {
    final id =
        JsonRead.string(json[mongoIdKey]) ?? JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('order block: id missing');
    return AssistantOrderSummaryModel(
      id: id,
      orderNumber: JsonRead.string(json[orderNumberKey]) ?? '',
      status: JsonRead.string(json[statusKey]) ?? '',
      total: JsonRead.integer(json[totalKey]) ?? 0,
      createdAt: JsonRead.dateTime(json[createdAtKey]),
      itemCount: JsonRead.integer(json[itemCountKey]) ?? 0,
      // `null` thumbnails (a product without a picture) are dropped.
      thumbnails: JsonRead.strings(json[thumbnailsKey]),
    );
  }
}
