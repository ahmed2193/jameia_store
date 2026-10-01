import '../../domain/entities/rider_chat.dart';
import '../../domain/entities/rider_chat_message.dart';
import '../models/rider_chat_message_model.dart';
import '../models/rider_chat_model.dart';

extension RiderChatMessageMapper on RiderChatMessageModel {
  RiderChatMessage toEntity() => RiderChatMessage(
    id: id,
    fromRider: from == RiderChatMessageModel.riderSide,
    sentAt: sentAt,
    textEn: translated[RiderChatMessageModel.enKey] ?? text,
    textAr: translated[RiderChatMessageModel.arKey] ?? text,
  );
}

extension RiderChatMapper on RiderChatModel {
  RiderChat toEntity() => RiderChat(
    messages: [for (final message in messages) message.toEntity()],
    riderTyping: riderTyping,
    readUpTo: readUpTo,
  );
}
