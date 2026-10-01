import 'dart:async';
import 'dart:developer';

import '../../domain/entities/rider_quick_reply.dart';
import '../models/courier_fix_model.dart';
import '../models/rider_chat_message_model.dart';
import '../models/rider_chat_model.dart';
import 'demo_rider_chat.dart';
import 'rider_chat_data_source.dart';

/// The rider's side of the chat, simulated (dummy data until the backend
/// has a rider chat): the rider says hello when the chat first opens, reads
/// each message and answers after a moment — typing first, like a person —
/// in both app languages, as a translating chat would. The words fit the
/// one-tap replies; anything typed gets a thank-you. Following the ride
/// (the rider feed it is given), the rider also writes on their own when they
/// are a couple of minutes away and at the door. One conversation per ride:
/// once the rider is at the door it is over, and the next map opened for the
/// order (a new ride) starts a fresh one. The conversation keeps how far the
/// customer has read it.
class DemoRiderChatDataSource implements RiderChatDataSource {
  DemoRiderChatDataSource({
    DateTime Function()? now,
    this.readAfter = defaultReadAfter,
    this.replyAfter = defaultReplyAfter,
    this._ride,
  }) : _now = now ?? DateTime.now;

  static const Duration defaultReadAfter = Duration(milliseconds: 900);
  static const Duration defaultReplyAfter = Duration(milliseconds: 2200);

  static const (String, String) greeting = (
    "Hi! I have your order and I'm on my way 🛵",
    'مرحبًا! طلبك معي وأنا في الطريق إليك 🛵',
  );

  /// What the rider writes a couple of minutes out, and at the door.
  static const (String, String) almostThere = (
    "I'm about 2 minutes away — see you soon!",
    'باقي لي تقريبًا دقيقتين — أشوفك قريب!',
  );
  static const (String, String) atTheDoor = (
    "I'm at your door 🚪",
    'أنا عند الباب 🚪',
  );

  /// Seconds to the door at which the rider says they are almost there:
  /// two minutes, so the live card reads "2 min" as the message says.
  static const int almostThereSeconds = 120;

  static const String _logName = 'courier';

  final DateTime Function() _now;
  final Stream<CourierFixModel> Function(String orderId)? _ride;

  /// How long the rider takes to read a message, then to type the answer.
  final Duration readAfter;
  final Duration replyAfter;
  final Map<String, DemoRiderChat> _chats = <String, DemoRiderChat>{};

  /// The orders whose ride reached the door: their conversation is over.
  final Set<String> _ended = <String>{};

  @override
  Stream<RiderChatModel> watch(String orderId) {
    // A watch after the door belongs to a new ride: a fresh conversation.
    if (_ended.remove(orderId)) _chats.remove(orderId);
    return _chatOf(orderId).watch();
  }

  @override
  Future<void> markRead(String orderId, DateTime at) async =>
      _chatOf(orderId).markRead(at);

  @override
  Future<void> send(
    String orderId,
    String text, {
    RiderQuickReply? quick,
  }) async {
    final chat = _chatOf(orderId)
      ..add(from: RiderChatMessageModel.customerSide, at: _now(), text: text);
    Timer(readAfter, () => _riderWrites(chat, answerTo(quick)));
  }

  /// The rider types [words] (English, Arabic), then sends them.
  void _riderWrites(DemoRiderChat chat, (String, String) words) {
    final (text, textAr) = words;
    chat.typing(true);
    Timer(replyAfter, () {
      chat
        ..typing(false)
        ..add(
          from: RiderChatMessageModel.riderSide,
          at: _now(),
          text: text,
          textAr: textAr,
        );
    });
  }

  /// Writes as the ride goes: almost there, then at the door (once each).
  void _follow(String orderId, DemoRiderChat chat) {
    final ride = _ride;
    if (ride == null) return;
    var almost = false;
    StreamSubscription<CourierFixModel>? feed;
    feed = ride(orderId).listen((fix) {
      final eta = fix.etaSeconds;
      if (!almost &&
          fix.state == CourierFixModel.onTheWayState &&
          eta != null &&
          eta <= almostThereSeconds) {
        almost = true;
        _riderWrites(chat, almostThere);
      }
      if (fix.state == CourierFixModel.arrivedState) {
        _ended.add(orderId);
        _riderWrites(chat, atTheDoor);
        unawaited(feed?.cancel());
      }
    }, onError: (Object error) => log('chat ride: $error', name: _logName));
  }

  DemoRiderChat _chatOf(String orderId) => _chats.putIfAbsent(orderId, () {
    final chat = DemoRiderChat(orderId);
    final (hello, helloAr) = greeting;
    chat.add(
      from: RiderChatMessageModel.riderSide,
      at: _now(),
      text: hello,
      textAr: helloAr,
    );
    _follow(orderId, chat);
    return chat;
  });

  /// The rider's answer (English, Arabic) to [quick], or to a typed message.
  static (String, String) answerTo(RiderQuickReply? quick) => switch (quick) {
    RiderQuickReply.leaveAtDoor => (
      "Sure, I'll leave it at your door 👍",
      'أكيد، راح أتركه عند الباب 👍',
    ),
    RiderQuickReply.callOnArrival => (
      "Okay, I'll call you when I arrive 📞",
      'تمام، راح أتصل عليك لما أوصل 📞',
    ),
    RiderQuickReply.comingDown => (
      'Great, see you in a moment!',
      'ممتاز، أشوفك بعد شوي!',
    ),
    RiderQuickReply.whereAreYou => (
      "I'm on my way — you can follow me on the map 🛵",
      'أنا في الطريق — تقدر تتابعني على الخريطة 🛵',
    ),
    null => ('Got it, thanks! 🙏', 'وصلت، شكرًا! 🙏'),
  };
}
