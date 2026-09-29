import 'package:equatable/equatable.dart';

/// The answer to an opened ticket: its id, and the server's confirmation
/// line (in the request language).
class SupportTicketReceipt extends Equatable {
  const SupportTicketReceipt({required this.ticketId, this.message = ''});

  final String ticketId;
  final String message;

  @override
  List<Object?> get props => [ticketId, message];
}
