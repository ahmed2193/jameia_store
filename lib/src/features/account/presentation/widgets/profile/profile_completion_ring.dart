import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../domain/entities/profile_completion.dart';
import 'profile_completion_ring_painter.dart';

/// The completion ring of the profile header, white on the brand hero. It
/// paints the current share at
/// once when the form opens (nothing counts up on open) and glides from the
/// value it showed to the new one as fields are filled in or cleared. When
/// the last field fills in, a check pops into the middle; a profile that was
/// complete on open (and stayed so) shows the check still.
class ProfileCompletionRing extends StatefulWidget {
  const ProfileCompletionRing({super.key, required this.completion});

  final ProfileCompletion completion;

  static const double diameter = AppSize.s64;
  static const double _stroke = AppSize.s6;

  /// The room inside the stroke, with a little air: large text scales the
  /// share down to fit rather than spilling over the ring.
  static const double _inner = diameter - 4 * _stroke;
  static const double _checkSize = AppSize.s30;
  static const int _percentScale = 100;
  static const double _trackAlpha = 0.3;
  static final Color _track = AppColors.white.withValues(alpha: _trackAlpha);

  @override
  State<ProfileCompletionRing> createState() => _ProfileCompletionRingState();
}

class _ProfileCompletionRingState extends State<ProfileCompletionRing> {
  /// Complete since the form opened: the check is shown without a pop.
  late bool _quietCheck = widget.completion.isComplete;

  @override
  void didUpdateWidget(covariant ProfileCompletionRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.completion.isComplete) _quietCheck = false;
  }

  @override
  Widget build(BuildContext context) {
    final completion = widget.completion;
    final check = completion.isComplete
        ? const HeroIcon(
            HeroIcons.check,
            size: ProfileCompletionRing._checkSize,
            color: AppColors.white,
          )
        : null;
    final label = 'profile.completion_label'.tr(
      namedArgs: {'pct': Formatters.isolate('${completion.percent}%')},
    );
    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: ProfileCompletionRing.diameter,
            child: TweenAnimationBuilder<double>(
              // No `begin`: the first build paints the value as is.
              tween: Tween<double>(end: completion.ratio),
              duration: MotionGuard.duration(context, AppMotion.slow),
              curve: AppMotion.emphasizedDecelerate,
              builder: (context, progress, _) => CustomPaint(
                painter: ProfileCompletionRingPainter(
                  progress: progress,
                  color: AppColors.white,
                  trackColor: ProfileCompletionRing._track,
                  strokeWidth: ProfileCompletionRing._stroke,
                  textDirection: Directionality.of(context),
                ),
                child: Center(
                  child: check == null
                      ? SizedBox.square(
                          dimension: ProfileCompletionRing._inner,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                '${(progress * ProfileCompletionRing._percentScale).round()}%',
                                style: AppTextStyles.headingMedium.copyWith(
                                  fontWeight: AppTextStyles.bold,
                                  color: AppColors.white,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        )
                      : _quietCheck
                      ? check
                      : PopScale.onMount(
                          duration: AppSprings.snappy.duration,
                          curve: AppSprings.snappy,
                          child: check,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
