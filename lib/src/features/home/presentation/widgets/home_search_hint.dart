import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/motion/motion.dart';

/// The search pill's hint, suggesting what to look for: "Search products",
/// then "Search for "milk"", "Search for "bread""… one every
/// [AppMotion.carousel], each rolling up into view as the last rolls away,
/// the suggestion typing itself in letter by letter behind a caret.
///
/// Stays on the plain hint under reduced motion and with a screen reader on
/// (the pill's own label never changes), and rests while its tab is behind
/// another.
class HomeSearchHint extends StatefulWidget {
  const HomeSearchHint({super.key, required this.style});

  final TextStyle style;

  @override
  State<HomeSearchHint> createState() => _HomeSearchHintState();
}

class _HomeSearchHintState extends State<HomeSearchHint> {
  /// How far a line travels, as a share of its own height.
  static const double _travel = 0.8;
  static const String _listSeparator = ',';

  /// How long each letter of a suggestion takes to type.
  static const Duration _perLetter = Duration(milliseconds: 80);
  static const String _caret = '|';

  /// Stands in for the suggestion in the translated line, to split it there.
  static const String _slot = '\u0000';

  /// "Every letter", for a suggestion that is done typing.
  static const int _allLetters = 1 << 20;

  Timer? _rotation;
  Timer? _typing;

  /// 0 is the plain hint; every step after it is the next suggestion.
  int _step = 0;

  /// How much of this step's suggestion is typed so far.
  int _typed = _allLetters;

  /// The store's suggestions, in the reader's language.
  List<String> get _suggestions => [
    for (final item in 'home.search_suggestions'.tr().split(_listSeparator))
      if (item.trim().isNotEmpty) item.trim(),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _rotation?.cancel();
    // Hidden or stilled, a half-typed suggestion finishes at once.
    _typing?.cancel();
    _typed = _allLetters;
    final still =
        MotionGuard.reduced(context) ||
        MediaQuery.accessibleNavigationOf(context);
    if (still) _step = 0;
    if (still ||
        _suggestions.isEmpty ||
        !TickerMode.valuesOf(context).enabled) {
      return;
    }
    _rotation = Timer.periodic(AppMotion.carousel, (_) => _nextStep());
  }

  @override
  void dispose() {
    _rotation?.cancel();
    _typing?.cancel();
    super.dispose();
  }

  void _nextStep() {
    if (!mounted) return;
    setState(() {
      _step++;
      _typed = 0;
    });
    _typing?.cancel();
    _typing = Timer.periodic(_perLetter, (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _typed++);
      if (_typed >= _suggestionAt(_step).characters.length) timer.cancel();
    });
  }

  String _suggestionAt(int step) {
    final suggestions = _suggestions;
    return suggestions.isEmpty
        ? ''
        : suggestions[(step - 1) % suggestions.length];
  }

  /// "Search for "mil|"": the line with as much of [item] as is typed.
  String _typedLine(String item) {
    final letters = item.characters;
    final line = 'home.search_for'.tr(namedArgs: {'item': _slot}).split(_slot);
    if (line.length != 2 || _typed >= letters.length) {
      return 'home.search_for'.tr(namedArgs: {'item': item});
    }
    return '${line.first}${letters.take(_typed)}$_caret${line.last}';
  }

  @override
  Widget build(BuildContext context) {
    final item = _step == 0 ? '' : _suggestionAt(_step);
    final text = item.isEmpty ? 'home.search_products'.tr() : _typedLine(item);
    final key = ValueKey<int>(_step);
    // The lines travel past the pill's text box, so they are cut at it.
    return ClipRect(
      child: AnimatedSwitcher(
        duration: MotionGuard.duration(context, AppMotion.page),
        switchInCurve: AppMotion.emphasizedDecelerate,
        switchOutCurve: AppMotion.exit,
        layoutBuilder: (current, previous) => Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [...previous, ?current],
        ),
        // The line arriving rises from below; the one leaving runs its
        // animation backwards, so the same tween carries it up and out.
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: Offset(0, child.key == key ? _travel : -_travel),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: Text(
          text,
          key: key,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: widget.style,
        ),
      ),
    );
  }
}
