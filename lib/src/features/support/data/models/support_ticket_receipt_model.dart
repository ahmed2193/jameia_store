import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// `POST /v1/support/tickets` → `{ message, ticketId }`.
class SupportTicketReceiptModel {
  const SupportTicketReceiptModel({required this.ticketId, this.message = ''});

  static const String ticketIdKey = 'ticketId';
  static const String messageKey = 'message';

  /// Throws [ParsingException] without a `ticketId`.
  factory SupportTicketReceiptModel.fromJson(Map<String, dynamic> json) {
    final ticketId = JsonRead.string(json[ticketIdKey]);
    if (ticketId == null) {
      throw const ParsingException('support ticket: ticketId missing');
    }
    return SupportTicketReceiptModel(
      ticketId: ticketId,
      message: JsonRead.string(json[messageKey]) ?? '',
    );
  }

  final String ticketId;
  final String message;
}
