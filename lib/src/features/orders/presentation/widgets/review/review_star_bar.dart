import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/motion/haptics.dart';
import '../../../domain/entities/product_review_request.dart';
import 'review_star_button.dart';

/// Five tappable stars; [rating] is 0 (not rated yet) to 5. When a tap fills
/// several stars at once they pop in one after another from the previous
/// rating (3 → 5: star 4, then star 5); stars that empty shrink out at once.
/// One selection haptic per tap. Shrinks to fit a narrow row.
class ReviewStarBar extends StatefulWidget {
  const ReviewStarBar({
    super.key,
    required this.rating,
    required this.onRate,
    this.enabled = true,
  });

  final int rating;
  final ValueChanged<int> onRate;

  /// A review already sent (or one in flight) cannot be re-rated.
  final bool enabled;

  @override
  State<ReviewStarBar> createState() => _ReviewStarBarState();
}

class _ReviewStarBarState extends State<ReviewStarBar> {
  /// The rating the latest fill cascades from.
  late int _from = widget.rating;

  @override
  void didUpdateWidget(ReviewStarBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rating != widget.rating) _from = oldWidget.rating;
  }

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (
            var star = ProductReviewRequest.minRating;
            star <= ProductReviewRequest.maxRating;
            star++
          )
            ReviewStarButton(
              key: ValueKey<int>(star),
              star: star,
              filled: star <= widget.rating,
              delaySteps: math.max(0, star - _from - 1),
              enabled: widget.enabled,
              onTap: () {
                Haptics.selection();
                widget.onRate(star);
              },
            ),
        ],
      ),
    );
  }
}
