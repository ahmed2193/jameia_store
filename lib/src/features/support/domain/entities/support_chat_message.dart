/// One chat bubble. [mine] = sent by the customer (end-aligned, brand
/// colour); otherwise the rider's (start-aligned, white).
class SupportChatMessage {
  const SupportChatMessage({
    required this.text,
    required this.mine,
    required this.time,
  });

  final String text;
  final bool mine;

  /// The clock label under the bubble.
  final String time;
}
