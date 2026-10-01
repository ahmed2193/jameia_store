import '../../domain/entities/rider_quick_reply.dart';
import '../models/rider_chat_model.dart';

/// The customer's chat with the rider of an order.
abstract class RiderChatDataSource {
  /// The conversation of [orderId], now and on every change.
  Stream<RiderChatModel> watch(String orderId);

  /// Sends [text] ([quick]: the one-tap reply it came from).
  Future<void> send(String orderId, String text, {RiderQuickReply? quick});

  /// The customer has read the conversation of [orderId] up to [at]. The
  /// conversation keeps how far (never back), so a map opened again counts
  /// only what came after; marking it tells no watcher.
  Future<void> markRead(String orderId, DateTime at);
}
