import '../../domain/entities/support_category.dart';
import '../../domain/entities/support_category_entity.dart';
import '../../domain/entities/support_ticket_draft.dart';
import '../../domain/entities/support_ticket_receipt.dart';
import '../models/support_category_model.dart';
import '../models/support_ticket_receipt_model.dart';

extension SupportCategoriesModelMapper on SupportCategoriesModel {
  /// The categories and topics this build can name; a key it does not know
  /// is left out (it could not be shown).
  List<SupportCategoryEntity> toEntities() => [
    for (final row in categories)
      if (SupportCategory.fromWire(row.key) case final category?)
        SupportCategoryEntity(
          category: category,
          requireOrder: row.requireOrder,
          requireProducts: row.requireProducts,
          topics: [
            for (final child in row.children)
              if (SupportTopic.fromWire(child.key) case final topic?)
                SupportTopicEntity(
                  topic: topic,
                  requireOrder: child.requireOrder,
                  requireProducts: child.requireProducts,
                ),
          ],
        ),
  ];
}

extension SupportTicketReceiptModelMapper on SupportTicketReceiptModel {
  SupportTicketReceipt toEntity() =>
      SupportTicketReceipt(ticketId: ticketId, message: message);
}

/// `POST /v1/support/tickets` body: only what the ticket has.
extension SupportTicketDraftMapper on SupportTicketDraft {
  static const String subjectField = 'subject';
  static const String categoryField = 'category';
  static const String subcategoryField = 'subcategory';
  static const String orderIdField = 'orderId';
  static const String productIdsField = 'productIds';
  static const String bodyField = 'body';

  Map<String, dynamic> toBody() {
    final topic = this.topic;
    final orderId = this.orderId;
    return <String, dynamic>{
      subjectField: subject.trim(),
      categoryField: category.wireValue,
      if (topic != null) subcategoryField: topic.wireValue,
      if (orderId != null && orderId.isNotEmpty) orderIdField: orderId,
      if (productIds.isNotEmpty) productIdsField: productIds,
      bodyField: body.trim(),
    };
  }
}
