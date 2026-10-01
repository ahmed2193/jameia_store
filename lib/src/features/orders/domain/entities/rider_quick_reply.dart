/// One-tap messages to the rider — what customers write most while they
/// wait — so nobody has to type at the door.
enum RiderQuickReply {
  leaveAtDoor('orders.chat_quick_leave_at_door'),
  callOnArrival('orders.chat_quick_call_on_arrival'),
  comingDown('orders.chat_quick_coming_down'),
  whereAreYou('orders.chat_quick_where_are_you');

  const RiderQuickReply(this.labelKey);

  /// The translation key of the message's words.
  final String labelKey;
}
