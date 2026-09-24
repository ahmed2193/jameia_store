import '../../../../core/data/mappers/order_mapper.dart';
import '../../domain/entities/cancel_order_request.dart';
import '../../domain/entities/orders_page.dart';
import '../../domain/entities/product_review_request.dart';
import '../models/orders_page_model.dart';

extension OrdersPageMapper on OrdersPageModel {
  OrdersPage toEntity() => OrdersPage(
    orders: items.toEntities(),
    page: page,
    hasMore: hasMore,
    total: total,
  );
}

/// `POST /v1/orders/{id}/cancel` body.
extension CancelOrderRequestMapper on CancelOrderRequest {
  static const String reasonField = 'reason';
  static const String noteField = 'note';

  Map<String, dynamic> toBody() {
    final trimmed = note.trim();
    return <String, dynamic>{
      reasonField: reason.wireValue,
      if (trimmed.isNotEmpty) noteField: trimmed,
    };
  }
}

/// `POST /v1/reviews` body.
extension ProductReviewRequestMapper on ProductReviewRequest {
  static const String productIdField = 'productId';
  static const String orderIdField = 'orderId';
  static const String ratingField = 'rating';
  static const String titleField = 'title';
  static const String bodyField = 'body';

  Map<String, dynamic> toBody() {
    final trimmedTitle = title.trim();
    final trimmedBody = body.trim();
    return <String, dynamic>{
      productIdField: productId,
      orderIdField: orderId,
      ratingField: rating,
      if (trimmedTitle.isNotEmpty) titleField: trimmedTitle,
      if (trimmedBody.isNotEmpty) bodyField: trimmedBody,
    };
  }
}
