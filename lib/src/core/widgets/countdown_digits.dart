import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_spacing.dart';
import '../../config/theme/app_text_styles.dart';
import '../motion/second_clock_follower.dart';
import '../motion/second_clock_scope.dart';
import 'countdown_digit_box.dart';

/// The Hero red-box countdown, "06 : 36 : 36" (hours : minutes : seconds),
/// for an offer that ends within [window].
///
/// It ticks on the nearest [SecondClockScope]'s clock: one timer for every
/// countdown on the page, aligned to the second, resting while the page is
/// covered. Each tick rebuilds this widget only (its boxes sit in a
/// `RepaintBoundary`), never the card around it. The clock reads left to
/// right in Arabic too. Screen readers get one label to the MINUTE ("Ends in
/// 6 h 36 min"), so the semantics tree changes once a minute, not every
/// second. At zero it shows nothing, lets go of the clock and calls [onEnded]
/// once — it never refetches.
///
/// Without a scope it shows the time left when it was built (and asserts in
/// debug). Reduced motion does not stop it: only the digits change. The
/// clock half is shared with the home strip's countdown
/// ([SecondClockFollower]).
class CountdownDigits extends StatefulWidget {
  const CountdownDigits({super.key, required this.endsAt, this.onEnded});

  /// An offer ending sooner than this counts down; later ones show a date.
  static const Duration window = Duration(days: 1);

  /// True when [endsAt] is in the future and at most [window] away.
  static bool countsDown(DateTime? endsAt, DateTime now) {
    if (endsAt == null) return false;
    final left = endsAt.difference(now);
    return left > Duration.zero && left <= window;
  }

  final DateTime endsAt;

  /// Called once, when the countdown reaches zero.
  final VoidCallback? onEnded;

  @override
  State<CountdownDigits> createState() => _CountdownDigitsState();
}

class _CountdownDigitsState extends State<CountdownDigits>
    with SecondClockFollower<CountdownDigits> {
  static const int _pad = 2;
  static const String _colon = ':';

  bool _looked = false;
  bool _ended = false;

  DateTime get _now => clockNow;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_looked) return;
    _looked = true;
    followClock(SecondClockScope.maybeOf(context));
    assert(
      followedClock != null,
      'CountdownDigits needs a SecondClockScope above it to tick.',
    );
    _sync();
  }

  @override
  void didUpdateWidget(CountdownDigits oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.endsAt == oldWidget.endsAt) return;
    _ended = false;
    _sync();
  }

  /// Listens while the countdown runs (in the window, not ended).
  void _sync() {
    if (followedClock == null) return;
    listenToClock(!_ended && CountdownDigits.countsDown(widget.endsAt, _now));
  }

  @override
  void onClockTick() {
    if (!mounted) return;
    if (widget.endsAt.difference(_now) <= Duration.zero && !_ended) {
      _ended = true;
      stopListeningToClock();
      widget.onEnded?.call();
    }
    setState(() {});
  }

  static String _two(int value) => '$value'.padLeft(_pad, '0');

  @override
  Widget build(BuildContext context) {
    final left = widget.endsAt.difference(_now);
    if (left <= Duration.zero) return const SizedBox.shrink();
    final minutes = left.inMinutes % Duration.minutesPerHour;
    final colon = Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s2),
      child: Text(
        _colon,
        style: AppTextStyles.tag.copyWith(color: AppColors.couponBadgeRed),
      ),
    );
    return Semantics(
      container: true,
      label: 'core.countdown_label'.tr(
        namedArgs: {'hours': '${left.inHours}', 'minutes': '$minutes'},
      ),
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CountdownDigitBox(digits: _two(left.inHours)),
                colon,
                CountdownDigitBox(digits: _two(minutes)),
                colon,
                CountdownDigitBox(
                  digits: _two(left.inSeconds % Duration.secondsPerMinute),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
