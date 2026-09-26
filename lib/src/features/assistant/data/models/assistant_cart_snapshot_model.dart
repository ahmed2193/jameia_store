import '../../../../core/data/models/json_read.dart';

/// Name + picture of one line of a `cart_summary` cart.
class AssistantCartPreviewModel {
  const AssistantCartPreviewModel({required this.name, this.image = ''});

  final String name;
  final String image;
}

/// The few fields of a `cart_summary` block's `cart` (the full
/// `GET /v1/cart` shape) that the summary card shows. The cart feature's
/// DTOs stay private to it; the live cart is `CartCubit`'s.
class AssistantCartSnapshotModel {
  const AssistantCartSnapshotModel({
    this.itemCount = 0,
    this.total = 0,
    this.minOrder = 0,
    this.meetsMinOrder = true,
    this.previews = const <AssistantCartPreviewModel>[],
  });

  static const String itemCountKey = 'itemCount';
  static const String totalsKey = 'totals';
  static const String totalKey = 'total';
  static const String minOrderKey = 'minOrder';
  static const String meetsMinOrderKey = 'meetsMinOrder';
  static const String linesKey = 'lines';
  static const String productKey = 'product';
  static const String nameKey = 'name';
  static const String imageKey = 'image';

  /// Thumbnails the card has room for.
  static const int maxPreviews = 4;

  final int itemCount;
  final int total;
  final int minOrder;
  final bool meetsMinOrder;
  final List<AssistantCartPreviewModel> previews;

  /// Never throws: a cart without totals is an empty snapshot.
  factory AssistantCartSnapshotModel.fromJson(Map<String, dynamic> json) {
    final totals = JsonRead.object(json[totalsKey]) ?? const {};
    final lines = json[linesKey];
    final previews = <AssistantCartPreviewModel>[];
    if (lines is List) {
      for (final line in lines) {
        if (previews.length == maxPreviews) break;
        final product = JsonRead.object(JsonRead.object(line)?[productKey]);
        final name = JsonRead.string(product?[nameKey]);
        if (name == null) continue;
        previews.add(
          AssistantCartPreviewModel(
            name: name,
            image: JsonRead.string(product?[imageKey]) ?? '',
          ),
        );
      }
    }
    return AssistantCartSnapshotModel(
      itemCount: JsonRead.integer(json[itemCountKey]) ?? 0,
      total: JsonRead.integer(totals[totalKey]) ?? 0,
      minOrder: JsonRead.integer(totals[minOrderKey]) ?? 0,
      meetsMinOrder: JsonRead.flag(totals[meetsMinOrderKey], fallback: true),
      previews: previews,
    );
  }
}
