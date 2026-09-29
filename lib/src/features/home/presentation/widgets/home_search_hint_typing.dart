import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';

/// One suggestion of the search pill's hint — "Search for "milk"" — that
/// types itself in letter by letter behind a caret once it is shown (see
/// [HomeSearchHint]). Stilled (reduced motion, a screen reader, a hidden
/// tab) it shows the whole line at once.
class HomeSearchHintTyping extends StatefulWidget {
  const HomeSearchHintTyping({
    super.key,
    required this.item,
    required this.style,
  });

  final String item;
  final TextStyle style;

  @override
  State<HomeSearchHintTyping> createState() => _HomeSearchHintTypingState();
}

class _HomeSearchHintTypingState extends State<HomeSearchHintTyping> {
  /// How long each letter of a suggestion takes to type.
  static const Duration _perLetter = Duration(milliseconds: 80);
  static const String _caret = '|';

  /// Stands in for the suggestion in the translated line, to split it there.
  static const String _slot = '\u0000';

  Timer? _typing;
  int _typed = 0;
  bool _started = false;

  int get _letters => widget.item.characters.length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!MotionGuard.ambientAllowed(context)) {
      // Hidden or stilled: a half-typed suggestion finishes at once.
      _finish();
      return;
    }
    if (_started) return;
    _started = true;
    _typing = Timer.periodic(_perLetter, (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _typed++);
      if (_typed >= _letters) _finish();
    });
  }

  void _finish() {
    _started = true;
    _typing?.cancel();
    _typing = null;
    _typed = _letters;
  }

  @override
  void dispose() {
    _typing?.cancel();
    super.dispose();
  }

  /// "Search for "mil|"": the line with as much of the item as is typed.
  String get _line {
    final item = widget.item;
    final line = 'home.search_for'.tr(namedArgs: {'item': _slot}).split(_slot);
    if (line.length != 2 || _typed >= _letters) {
      return 'home.search_for'.tr(namedArgs: {'item': item});
    }
    return '${line.first}${item.characters.take(_typed)}$_caret${line.last}';
  }

  @override
  Widget build(BuildContext context) => Text(
    _line,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: widget.style,
  );
}
