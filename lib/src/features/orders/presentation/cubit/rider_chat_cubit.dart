import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../domain/entities/rider_chat.dart';
import '../../domain/entities/rider_quick_reply.dart';
import '../../domain/usecases/mark_rider_chat_read_usecase.dart';
import '../../domain/usecases/send_rider_message_usecase.dart';
import '../../domain/usecases/watch_rider_chat_usecase.dart';
import 'rider_chat_state.dart';

/// The customer's chat with their rider, from the moment the rider heads
/// their way ([start]): the conversation live, the unread count on the map
/// while the sheet is shut (counted from how far the conversation says the
/// customer read, so a map opened again does not count old messages), and
/// one message sent at a time. An empty or over-long message is simply not
/// sent (the composer prevents both).
class RiderChatCubit extends Cubit<RiderChatState>
    with SafeCubitMixin<RiderChatState> {
  RiderChatCubit({
    required this._watch,
    required this._send,
    required this._markRead,
  }) : super(const RiderChatState());

  final WatchRiderChatUseCase _watch;
  final SendRiderMessageUseCase _send;
  final MarkRiderChatReadUseCase _markRead;

  StreamSubscription<RiderChat>? _feed;
  String? _orderId;

  /// Follows the chat of [orderId] (once; again only for another order).
  void start(String orderId) {
    if (_orderId == orderId || isClosed) return;
    _orderId = orderId;
    unawaited(_feed?.cancel());
    _feed = _watch(WatchRiderChatParams(orderId)).listen(
      (chat) => safeEmit(
        state.copyWith(
          chat: chat,
          readUpTo: state.open
              ? _lastAt(chat)
              : (state.readUpTo ?? chat.readUpTo),
        ),
      ),
      onError: (Object error) => safeEmit(
        state.copyWith(
          failure: error is Failure ? error : const UnexpectedFailure(),
        ),
      ),
    );
  }

  /// The sheet opened: everything in it is read.
  void opened() => _read(open: true);

  /// The sheet closed: what came before is read; later messages count.
  void closed() => _read(open: false);

  /// Read up to the last message, here and in the conversation (a marker
  /// only: its result changes nothing on screen).
  void _read({required bool open}) {
    final at = _lastAt(state.chat);
    safeEmit(state.copyWith(open: open, readUpTo: at));
    final orderId = _orderId;
    if (orderId == null || at == null) return;
    unawaited(_markRead(MarkRiderChatReadParams(orderId, at)));
  }

  /// Sends [text] ([quick]: the one-tap reply it came from); `true` once it
  /// is on its way.
  Future<bool> send(String text, {RiderQuickReply? quick}) async {
    final orderId = _orderId;
    if (orderId == null || state.sending || isClosed) return false;
    safeEmit(state.copyWith(sending: true));
    final result = await _send(
      SendRiderMessageParams(orderId: orderId, text: text, quick: quick),
    );
    return result.fold(
      (failure) {
        safeEmit(
          state.copyWith(
            sending: false,
            failure: failure is ValidationFailure ? null : failure,
          ),
        );
        return false;
      },
      (_) {
        safeEmit(state.copyWith(sending: false));
        return true;
      },
    );
  }

  static DateTime? _lastAt(RiderChat chat) =>
      chat.messages.isEmpty ? null : chat.messages.last.sentAt;

  @override
  Future<void> close() async {
    await _feed?.cancel();
    return super.close();
  }
}
