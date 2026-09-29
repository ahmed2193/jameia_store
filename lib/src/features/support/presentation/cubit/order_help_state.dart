import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/screen_loader_mixin.dart';
import '../../domain/entities/order_help_issue.dart';
import '../../domain/entities/order_help_request.dart';
import '../../domain/entities/support_ticket_receipt.dart';

class OrderHelpState extends Equatable
    implements ScreenLoadState<OrderHelpState> {
  const OrderHelpState({
    this.load = const ScreenLoad(),
    this.groups = const <OrderHelpIssueGroup>[],
    this.request = const OrderHelpRequest(),
    this.isSending = false,
    this.receipt,
  });

  /// The taxonomy's read, and the failure of a send (told as the customer's
  /// action: offline it needs the internet; signed out → sign in).
  @override
  final ScreenLoad load;

  /// "What went wrong?" options, grouped.
  final List<OrderHelpIssueGroup> groups;

  /// What the customer has chosen and written.
  final OrderHelpRequest request;
  final bool isSending;

  /// Set once the ticket is open: the page thanks the customer.
  final SupportTicketReceipt? receipt;

  bool get sent => receipt != null;
  bool get canSend => request.canSend && !isSending && !sent;

  /// The reason there is nothing to show; `null` once the options are in.
  Failure? get loadFailure => load.hasFailed ? load.failure : null;

  @override
  OrderHelpState withLoad(ScreenLoad load) => copyWith(load: load);

  OrderHelpState copyWith({
    ScreenLoad? load,
    List<OrderHelpIssueGroup>? groups,
    OrderHelpRequest? request,
    bool? isSending,
    SupportTicketReceipt? receipt,
  }) => OrderHelpState(
    load: load ?? this.load.settled(),
    groups: groups ?? this.groups,
    request: request ?? this.request,
    isSending: isSending ?? this.isSending,
    receipt: receipt ?? this.receipt,
  );

  @override
  List<Object?> get props => [load, groups, request, isSending, receipt];
}
