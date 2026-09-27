import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/motion/motion.dart';

/// [text] typing itself out, letter by letter, while the mascot talks; then
/// [onDone]. The full text is laid out from the first frame (unseen), so the
/// card never grows while it types, and screen readers get it whole at once.
/// Reduced motion: shown whole, [onDone] right after the first frame.
class AssistantBuddyTypedText extends StatefulWidget {
  const AssistantBuddyTypedText({
    super.key,
    required this.text,
    required this.style,
    required this.onDone,
  });

  final String text;
  final TextStyle style;
  final VoidCallback onDone;

  @override
  State<AssistantBuddyTypedText> createState() =>
      _AssistantBuddyTypedTextState();
}

class _AssistantBuddyTypedTextState extends State<AssistantBuddyTypedText>
    with SingleTickerProviderStateMixin {
  static const int _perLetterMs = 24;
  static const int _minMs = 500;
  static const int _maxMs = 1500;
  static const int _maxLines = 3;

  late final List<String> _letters = widget.text.characters.toList();
  late final AnimationController _typing = AnimationController(
    vsync: this,
    duration: Duration(
      milliseconds: (_letters.length * _perLetterMs).clamp(_minMs, _maxMs),
    ),
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
        if (mounted) widget.onDone();
      });
      return;
    }
    // Completes only when the typing ends by itself (not on dispose).
    _typing.forward().then((_) {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _typing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.text,
      child: ExcludeSemantics(
        child: Stack(
          children: [
            Text(
              widget.text,
              maxLines: _maxLines,
              overflow: TextOverflow.ellipsis,
              style: widget.style.copyWith(color: AppColors.scrimTransparent),
            ),
            AnimatedBuilder(
              animation: _typing,
              builder: (context, _) => Text(
                _letters.take((_letters.length * _typing.value).ceil()).join(),
                maxLines: _maxLines,
                overflow: TextOverflow.ellipsis,
                style: widget.style,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
