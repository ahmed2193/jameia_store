import 'package:equatable/equatable.dart';

import 'support_category.dart';

/// A ticket to open (`POST /v1/support/tickets`): what it is about, the
/// order and products it concerns, and the customer's words. The limits are
/// the API's.
class SupportTicketDraft extends Equatable {
  const SupportTicketDraft({
    required this.subject,
    required this.category,
    required this.body,
    this.topic,
    this.orderId,
    this.productIds = const <String>[],
  });

  static const int maxSubjectLength = 200;
  static const int maxBodyLength = 4000;

  final String subject;
  final SupportCategory category;
  final SupportTopic? topic;
  final String? orderId;
  final List<String> productIds;
  final String body;

  /// The API would take it: a subject and a body, each within its limit.
  bool get isValid {
    final subject = this.subject.trim();
    final body = this.body.trim();
    return subject.isNotEmpty &&
        subject.length <= maxSubjectLength &&
        body.isNotEmpty &&
        body.length <= maxBodyLength;
  }

  @override
  List<Object?> get props => [
    subject,
    category,
    topic,
    orderId,
    productIds,
    body,
  ];
}
