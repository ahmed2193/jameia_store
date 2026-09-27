import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import 'assistant_buddy_typing_caret.dart';
import 'assistant_buddy_typing_rhythm.dart';

/// A thought typing itself out at a natural pace
/// ([AssistantBuddyTypingRhythm]), a caret running ahead of the letters;
/// then [onTyped]. The whole line is laid out from the first letter
/// (unseen), so the bubble has its final size at once and hugs the longest
/// line. Reduced motion: the line shows whole.
class AssistantBuddyThoughtText extends StatefulWidget {
  const AssistantBuddyThoughtText({
    super.key,
    required this.text,
    required this.style,
    required this.onTyped,
  });

  final String text;
  final TextStyle style;
  final VoidCallback onTyped;

  @override
  State<AssistantBuddyThoughtText> createState() =>
      _AssistantBuddyThoughtTextState();
}

class _AssistantBuddyThoughtTextState extends State<AssistantBuddyThoughtText>
    with SingleTickerProviderStateMixin {
  /// The caret is a little taller than the letters' size.
  static const double _caretToFont = 1.15;

  late final List<String> _letters = widget.text.characters.toList();
  late final AssistantBuddyTypingRhythm _rhythm = AssistantBuddyTypingRhythm(
    _letters,
  );
  late final AnimationController _typing = AnimationController(
    vsync: this,
    duration: _rhythm.length,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MotionGuard.reduced(context)) {
      _typing.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onTyped();
      });
      return;
    }
    // Completes only when the typing ends by itself (not on dispose).
    _typing.forward().then((_) {
      if (mounted) widget.onTyped();
    });
  }

  @override
  void dispose() {
    _typing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final caret = (widget.style.fontSize ?? AppSize.font14) * _caretToFont;
    return Stack(
      children: [
        Text(
          widget.text,
          textWidthBasis: TextWidthBasis.longestLine,
          style: widget.style.copyWith(color: AppColors.scrimTransparent),
        ),
        AnimatedBuilder(
          animation: _typing,
          builder: (context, _) => Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _letters
                      .take(_rhythm.shownAt(_rhythm.length * _typing.value))
                      .join(),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: AssistantBuddyTypingCaret(
                    visible: _typing.isAnimating,
                    height: caret,
                  ),
                ),
              ],
            ),
            textWidthBasis: TextWidthBasis.longestLine,
            style: widget.style,
          ),
        ),
      ],
    );
  }
}
