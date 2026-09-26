import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/entities/assistant_thread.dart';
import '../../cubit/assistant_chat_cubit.dart';
import '../../cubit/assistant_chat_state.dart';
import 'assistant_anchored_item.dart';
import 'assistant_anchored_scroll_physics.dart';
import 'assistant_jump_to_latest.dart';
import 'assistant_scroll_anchor.dart';
import 'assistant_thread_row.dart';

/// The conversation, newest at the bottom (a reversed lazy list, so a long
/// history opens at its end without measuring it).
///
/// Rows keep their elements when rows are added (keyed +
/// `findChildIndexCallback`); a row animates only on its first appearance in
/// this session's flow (a sent message, the reply taking shape) — never when
/// a history loads. The list follows a reply while the reader is at the
/// bottom and keeps their place when they are not (see
/// [AssistantAnchoredScrollPhysics]); sending always returns to the bottom.
class AssistantMessageList extends StatefulWidget {
  const AssistantMessageList({super.key});

  @override
  State<AssistantMessageList> createState() => _AssistantMessageListState();
}

class _AssistantMessageListState extends State<AssistantMessageList> {
  /// More new rows than this at once is a loaded history, not a live flow.
  static const int _maxAnimatedAtOnce = 2;

  final ScrollController _scroll = ScrollController();
  final AssistantScrollAnchor _anchor = AssistantScrollAnchor();
  late final ScrollPhysics _physics = AssistantAnchoredScrollPhysics(
    anchor: _anchor,
  );

  /// Every row key this list has shown.
  final Set<String> _known = <String>{};

  /// Rows that may play their entrance, and those that already did.
  Set<String> _fresh = const <String>{};
  final Set<String> _played = <String>{};

  /// Row index by key, as last built (`findChildIndexCallback`).
  Map<String, int> _indexByKey = const <String, int>{};

  /// The reader is away from the newest message: the jump button shows.
  final ValueNotifier<bool> _awayFromLatest = ValueNotifier<bool>(false);

  /// Beyond this far from the newest message, "Jump to latest" shows.
  static const double _jumpThreshold = AppSize.s200;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScrolled);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _awayFromLatest.dispose();
    super.dispose();
  }

  void _onScrolled() {
    if (_scroll.hasClients) _updateAway(_scroll.offset);
  }

  /// Also called on metrics changes: the list keeping the reader's place
  /// moves the offset without a scroll event.
  bool _onMetrics(ScrollMetricsNotification notification) {
    _updateAway(notification.metrics.pixels);
    return false;
  }

  void _updateAway(double offset) =>
      _awayFromLatest.value = offset > _jumpThreshold;

  void _jumpToLatest() {
    if (!_scroll.hasClients) return;
    if (MotionGuard.reduced(context)) {
      _scroll.jumpTo(0);
      return;
    }
    _anchor.suspended = true;
    _scroll
        .animateTo(0, duration: AppMotion.page, curve: AppMotion.signature)
        .whenComplete(() => _anchor.suspended = false);
  }

  List<String> _keysOf(_Rows rows) => [
    ?rows.liveKey,
    for (final entry in rows.entries.reversed) entry.key,
  ];

  /// A history opening (the first rows, nothing streaming) or many rows
  /// at once never animate.
  void _markFresh(List<String> keys, {required bool streaming}) {
    final fresh = {
      for (final key in keys)
        if (!_known.contains(key)) key,
    };
    final opening = _known.isEmpty && !streaming;
    _fresh = opening || fresh.length > _maxAnimatedAtOnce
        ? const <String>{}
        : fresh;
    _known.addAll(keys);
  }

  bool get _isFollowing =>
      !_scroll.hasClients ||
      _scroll.offset <= AssistantAnchoredScrollPhysics.followThreshold;

  /// After a send, or a new row while following, bring the newest row
  /// into view once it is laid out.
  void _revealNewest({required bool always}) {
    if (!always && !_isFollowing) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _jumpToLatest();
    });
  }

  static String? _newestKey(AssistantChatState state) =>
      state.isStreaming ? state.liveTurn?.key : state.thread.lastKey;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AssistantChatCubit, AssistantChatState>(
      listenWhen: (previous, current) =>
          _newestKey(previous) != _newestKey(current),
      // A new turn is always shown; any other new row only while following.
      listener: (context, state) => _revealNewest(always: state.isStreaming),
      child: BlocSelector<AssistantChatCubit, AssistantChatState, _Rows>(
        selector: _Rows.of,
        builder: (context, rows) {
          final keys = _keysOf(rows);
          _markFresh(keys, streaming: rows.liveKey != null);
          _indexByKey = {for (final (index, key) in keys.indexed) key: index};
          final entries = {for (final entry in rows.entries) entry.key: entry};
          return Stack(
            children: [
              NotificationListener<ScrollMetricsNotification>(
                onNotification: _onMetrics,
                child: ListView.builder(
                  controller: _scroll,
                  physics: _physics,
                  reverse: true,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s12,
                  ),
                  itemCount: keys.length,
                  findChildIndexCallback: (key) =>
                      key is ValueKey<String> ? _indexByKey[key.value] : null,
                  itemBuilder: (context, index) {
                    final key = keys[index];
                    return KeyedSubtree(
                      key: ValueKey<String>(key),
                      child: AssistantAnchoredItem(
                        anchor: _anchor,
                        rowKey: key,
                        isNewest: index == 0,
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            top: AppSpacing.s12,
                          ),
                          child: AssistantThreadRow(
                            rowKey: key,
                            entry: entries[key],
                            isLast: index == 0,
                            animate: _fresh.contains(key) && _played.add(key),
                            canSend: rows.canSend,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              PositionedDirectional(
                bottom: AppSpacing.s12,
                start: 0,
                end: 0,
                child: Center(
                  child: AssistantJumpToLatest(
                    visible: _awayFromLatest,
                    onTap: _jumpToLatest,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// What the list rebuilds on: the stored rows, the streamed reply's key
/// (its content is read by the row itself) and whether a message may go.
/// A streamed word changes none of these.
class _Rows {
  const _Rows({required this.entries, required this.canSend, this.liveKey});

  factory _Rows.of(AssistantChatState state) {
    final live = state.liveTurn;
    final liveKey = live != null && live.isActive ? live.key : null;
    return _Rows(
      entries: state.thread.entries,
      canSend: state.canSend,
      liveKey: liveKey,
    );
  }

  final List<AssistantThreadEntry> entries;
  final String? liveKey;
  final bool canSend;

  @override
  bool operator ==(Object other) =>
      other is _Rows &&
      identical(other.entries, entries) &&
      other.liveKey == liveKey &&
      other.canSend == canSend;

  @override
  int get hashCode => Object.hash(identityHashCode(entries), liveKey, canSend);
}
