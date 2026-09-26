import 'package:equatable/equatable.dart';

/// `POST /v1/assistant/conversations/{id}/handoff` → the support ticket a
/// person will answer. [message] is shown as sent.
class AssistantHandoffTicket extends Equatable {
  const AssistantHandoffTicket({
    required this.ticketId,
    this.ticketNumber = '',
    this.message = '',
  });

  final String ticketId;
  final String ticketNumber;
  final String message;

  @override
  List<Object?> get props => [ticketId, ticketNumber, message];
}
