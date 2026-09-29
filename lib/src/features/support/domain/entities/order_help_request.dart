import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/order_line_entity.dart';
import 'order_help_issue.dart';
import 'support_ticket_draft.dart';

/// What still stops an [OrderHelpRequest] from being sent, first gap first.
enum OrderHelpGap {
  /// No issue is chosen.
  issue,

  /// The issue needs the items it concerns, and none is ticked.
  products,

  /// The note is over the API's limit.
  noteTooLong,
}

/// What the customer has said on the order help page so far: the issue,
/// the items it concerns (by product id) and their own words. The rules of
/// when it can be sent live here, not in the page.
class OrderHelpRequest extends Equatable {
  const OrderHelpRequest({
    this.issue,
    this.productIds = const <String>{},
    this.note = '',
  });

  final OrderHelpIssue? issue;
  final Set<String> productIds;
  final String note;

  /// The chosen issue needs the items it concerns.
  bool get needsProducts => issue?.requireProducts == true;

  bool get noteTooLong => note.trim().length > SupportTicketDraft.maxBodyLength;

  /// The first thing missing before it can be sent; `null` once it can: an
  /// issue, its items when it needs them, and a note within the limit (the
  /// note may be empty: the page then describes the issue itself).
  OrderHelpGap? get gap => issue == null
      ? OrderHelpGap.issue
      : needsProducts && productIds.isEmpty
      ? OrderHelpGap.products
      : noteTooLong
      ? OrderHelpGap.noteTooLong
      : null;

  bool get canSend => gap == null;

  /// [productId] is ticked and goes with the ticket (ticks made under an
  /// issue that needs items are kept, but sent only with such an issue).
  bool picks(String productId) =>
      needsProducts && productIds.contains(productId);

  /// The order's [lines] this request is about, in the order's order.
  List<OrderLineEntity> pickedLines(List<OrderLineEntity> lines) => [
    for (final line in lines)
      if (picks(line.productId)) line,
  ];

  OrderHelpRequest withIssue(OrderHelpIssue issue) =>
      OrderHelpRequest(issue: issue, productIds: productIds, note: note);

  OrderHelpRequest toggleProduct(String productId) => OrderHelpRequest(
    issue: issue,
    productIds: productIds.contains(productId)
        ? ({...productIds}..remove(productId))
        : {...productIds, productId},
    note: note,
  );

  OrderHelpRequest withNote(String note) =>
      OrderHelpRequest(issue: issue, productIds: productIds, note: note);

  /// The ticket for order [orderId]: [subject] (cut to the API's limit), and
  /// the customer's note — or [fallbackBody] when they wrote none. The items
  /// go only with an issue that needs them. `null` while it cannot be sent.
  SupportTicketDraft? toDraft({
    required String orderId,
    required String subject,
    required String fallbackBody,
  }) {
    final issue = this.issue;
    if (issue == null || !canSend) return null;
    final written = note.trim();
    return SupportTicketDraft(
      subject: _clip(subject.trim(), SupportTicketDraft.maxSubjectLength),
      category: issue.category,
      topic: issue.topic,
      orderId: orderId,
      productIds: needsProducts
          ? (productIds.toList()..sort())
          : const <String>[],
      body: written.isEmpty
          ? _clip(fallbackBody.trim(), SupportTicketDraft.maxBodyLength)
          : written,
    );
  }

  static String _clip(String text, int max) =>
      text.length > max ? text.substring(0, max) : text;

  @override
  List<Object?> get props => [issue, productIds, note];
}
