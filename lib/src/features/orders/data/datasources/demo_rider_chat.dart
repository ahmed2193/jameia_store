import 'dart:async';

import '../models/rider_chat_message_model.dart';
import '../models/rider_chat_model.dart';

/// One simulated conversation: the messages so far, whether the rider is
/// typing, how far the customer has read it, and everyone watching it — each
/// watcher gets the conversation as it is on listening, then every change.
class DemoRiderChat {
  DemoRiderChat(this.orderId);

  final String orderId;
  final List<RiderChatMessageModel> _messages = <RiderChatMessageModel>[];
  final Set<StreamController<RiderChatModel>> _watchers =
      <StreamController<RiderChatModel>>{};
  bool _typing = false;
  int _count = 0;
  DateTime? _readUpTo;

  bool get isEmpty => _messages.isEmpty;

  RiderChatModel get snapshot => RiderChatModel(
    messages: List<RiderChatMessageModel>.unmodifiable(_messages),
    riderTyping: _typing,
    readUpTo: _readUpTo,
  );

  Stream<RiderChatModel> watch() {
    late final StreamController<RiderChatModel> watcher;
    watcher = StreamController<RiderChatModel>(
      onListen: () {
        watcher.add(snapshot);
        _watchers.add(watcher);
      },
      onCancel: () => _watchers.remove(watcher),
    );
    return watcher.stream;
  }

  /// A message from [from] ([RiderChatMessageModel.riderSide] or
  /// [RiderChatMessageModel.customerSide]), in both app languages when the
  /// rider wrote it.
  void add({
    required String from,
    required DateTime at,
    required String text,
    String? textAr,
  }) {
    _messages.add(
      RiderChatMessageModel(
        id: '$orderId-${++_count}',
        from: from,
        sentAt: at,
        text: text,
        translated: textAr == null
            ? const <String, String>{}
            : <String, String>{
                RiderChatMessageModel.enKey: text,
                RiderChatMessageModel.arKey: textAr,
              },
      ),
    );
    _emit();
  }

  /// Read up to [at] (never back). No watcher is told: the one reading knows
  /// already, and the next one gets it with the conversation.
  void markRead(DateTime at) {
    final read = _readUpTo;
    if (read == null || at.isAfter(read)) _readUpTo = at;
  }

  void typing(bool typing) {
    if (_typing == typing) return;
    _typing = typing;
    _emit();
  }

  void _emit() {
    final now = snapshot;
    for (final watcher in [..._watchers]) {
      watcher.add(now);
    }
  }
}
