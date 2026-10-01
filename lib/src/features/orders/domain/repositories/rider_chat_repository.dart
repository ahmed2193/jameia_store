import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/rider_chat.dart';
import '../entities/rider_quick_reply.dart';

/// The customer's chat with the rider of an order.
abstract class RiderChatRepository {
  /// The conversation of [orderId], now and on every change.
  Stream<RiderChat> watch(String orderId);

  /// Sends [text] to the rider ([quick]: the one-tap reply it came from).
  Future<Either<Failure, Unit>> send(
    String orderId,
    String text, {
    RiderQuickReply? quick,
  });

  /// The customer has read the conversation of [orderId] up to [at].
  Future<Either<Failure, Unit>> markRead(String orderId, DateTime at);
}
