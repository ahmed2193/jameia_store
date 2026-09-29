import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../assistant_stream_pace.dart';

/// What [AssistantStreamReveal] hands down to the reply's text blocks and
/// its caret: the words' [pace] on the reveal's [clock], and the caret's
/// [caret] opacity while it is still [caretShown] (writing, or fading out
/// after the stream ended). Rebuilds its readers only when the caret comes
/// or goes: the words follow [clock] themselves, block by block.
class AssistantStreamRevealScope extends InheritedWidget {
  const AssistantStreamRevealScope({
    super.key,
    required this.pace,
    required this.clock,
    required this.caret,
    required this.caretShown,
    required super.child,
  });

  final AssistantStreamPace pace;
  final ValueListenable<Duration> clock;
  final Animation<double> caret;
  final bool caretShown;

  static AssistantStreamRevealScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AssistantStreamRevealScope>();

  @override
  bool updateShouldNotify(AssistantStreamRevealScope oldWidget) =>
      caretShown != oldWidget.caretShown ||
      !identical(pace, oldWidget.pace) ||
      !identical(clock, oldWidget.clock);
}
