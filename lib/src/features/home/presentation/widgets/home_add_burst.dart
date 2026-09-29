import 'package:flutter/material.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/widgets/shelf_add_button.dart';
import '../../../../core/widgets/shelf_card_media.dart';

/// The card's own "got it" when the customer adds from it: a small green
/// "+1" rises from the card's round "+" and fades, and the card gives a quick
/// bump — beside the picture flying to the basket. It plays each time
/// [trigger] notifies (the card's add tap), never for a quantity that
/// arrived some other way (a restored basket, another screen), and not at
/// all under reduced motion.
class HomeAddBurst extends StatefulWidget {
  const HomeAddBurst({
    super.key,
    required this.trigger,
    required this.width,
    required this.child,
  });

  final Listenable trigger;

  /// Width of the card: the side of its square picture, whose bottom-end
  /// corner holds the round "+".
  final double width;
  final Widget child;

  @override
  State<HomeAddBurst> createState() => _HomeAddBurstState();
}

class _HomeAddBurstState extends State<HomeAddBurst>
    with SingleTickerProviderStateMixin {
  static const String _plusOne = '+1';

  /// The "+1" starts centred over the card's round "+" (the shelf card's
  /// [ShelfAddButton], [ShelfCardMedia.controlInset] in from the picture's
  /// bottom-end corner), its foot tucked this far behind the button's top,
  /// and rises by a share of its own height.
  static const double _tuck = AppSpacing.s4;
  static const double _rise = 1.5;

  /// The whole "+1" burst, rise to fade-out.
  static const Duration _burstLength = Duration(milliseconds: 700);

  /// In quickly, held, out slowly — invisible before and after.
  static final Animatable<double> _fade = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 1),
    TweenSequenceItem(tween: ConstantTween(1), weight: 3),
    TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: 3),
  ]);
  static final Animatable<Offset> _lift = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0, -_rise),
  ).chain(CurveTween(curve: AppMotion.emphasizedDecelerate));

  /// A quick swell of the card and back, at rest before and after.
  static final Animatable<double> _bump = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.03), weight: 1),
    TweenSequenceItem(tween: Tween(begin: 1.03, end: 1), weight: 2),
    TweenSequenceItem(tween: ConstantTween(1), weight: 4),
  ]).chain(CurveTween(curve: AppMotion.signature));

  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: _burstLength,
  );

  @override
  void initState() {
    super.initState();
    widget.trigger.addListener(_play);
  }

  @override
  void didUpdateWidget(covariant HomeAddBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) {
      oldWidget.trigger.removeListener(_play);
      widget.trigger.addListener(_play);
    }
  }

  @override
  void dispose() {
    widget.trigger.removeListener(_play);
    _burst.dispose();
    super.dispose();
  }

  void _play() {
    if (!mounted || MotionGuard.reduced(context)) return;
    _burst.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ScaleTransition(scale: _burst.drive(_bump), child: widget.child),
        // The column above the round "+": the "+1" stands on its foot, so
        // it starts at the button whatever the text scale makes its height.
        PositionedDirectional(
          top: 0,
          end: ShelfCardMedia.controlInset,
          width: ShelfAddButton.size,
          height:
              widget.width -
              ShelfCardMedia.controlInset -
              ShelfAddButton.size +
              _tuck,
          child: IgnorePointer(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FadeTransition(
                opacity: _burst.drive(_fade),
                child: SlideTransition(
                  position: _burst.drive(_lift),
                  child: Container(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.s6,
                      vertical: AppSpacing.s2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.martGreen,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      _plusOne,
                      maxLines: 1,
                      softWrap: false,
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
