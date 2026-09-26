import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/motion/confetti_burst.dart';

/// The home feed's party popper: a card calls [HomeConfetti.burstFrom] and a
/// handful of confetti in the brand's colours bursts up from that card, over
/// the whole feed (a rail would cut it off at its edges). Used for the first
/// thing that goes into an empty basket. Nothing under reduced motion
/// ([ConfettiBurst] rests), and the overlay never takes a touch.
class HomeConfetti extends StatefulWidget {
  const HomeConfetti({super.key, required this.child});

  final Widget child;

  /// Bursts from the middle of the top of [card]'s box; nothing when the
  /// card is not inside a [HomeConfetti].
  static void burstFrom(BuildContext card) =>
      card.findAncestorStateOfType<_HomeConfettiState>()?._burstFrom(card);

  @override
  State<HomeConfetti> createState() => _HomeConfettiState();
}

class _HomeConfettiState extends State<HomeConfetti> {
  static const List<Color> _colors = [
    AppColors.martGreen,
    AppColors.accent3,
    AppColors.accent4,
    AppColors.martGreenDark,
    AppColors.accent1,
  ];
  static const int _pieces = 36;

  int _shots = 0;
  Offset _origin = ConfettiBurst.defaultOrigin;

  void _burstFrom(BuildContext card) {
    final cardBox = card.findRenderObject();
    final feedBox = context.findRenderObject();
    if (cardBox is! RenderBox ||
        feedBox is! RenderBox ||
        !cardBox.hasSize ||
        !feedBox.hasSize ||
        feedBox.size.isEmpty) {
      return;
    }
    final from = cardBox.localToGlobal(
      cardBox.size.topCenter(Offset.zero),
      ancestor: feedBox,
    );
    setState(() {
      _origin = Offset(
        (from.dx / feedBox.size.width).clamp(0, 1),
        (from.dy / feedBox.size.height).clamp(0, 1),
      );
      _shots++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiBurst(
      playKey: _shots == 0 ? null : _shots,
      colors: _colors,
      origin: _origin,
      count: _pieces,
      child: widget.child,
    );
  }
}
