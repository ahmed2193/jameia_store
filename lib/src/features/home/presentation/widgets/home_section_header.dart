import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/app_size.dart';
import '../../domain/entities/home_icon.dart';
import 'home_accent_palette.dart';
import 'home_arrow_button.dart';
import 'home_icon_view.dart';
import 'home_layout.dart';
import 'home_reveal_scope.dart';

/// Title row of a home block: the backend's icon in its accent, the bold
/// title, and the round arrow to the whole collection when there is one.
/// As its block comes in, the icon pops into place and the arrow follows.
class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader({
    super.key,
    required this.title,
    this.icon = const HomeIcon(),
    this.accent = HomeAccent.none,
    this.onSeeAll,
  });

  final String title;
  final HomeIcon icon;
  final HomeAccent accent;
  final VoidCallback? onSeeAll;

  static const double _popFrom = 0.4;

  /// On the block's reveal clock: the icon pops in with a small overshoot,
  /// the arrow a beat later.
  static final Animatable<double> _iconPop =
      Tween<double>(begin: _popFrom, end: 1).chain(
        CurveTween(
          curve: const Interval(0.15, 0.65, curve: AppMotion.emphasized),
        ),
      );
  static final Animatable<double> _arrowPop =
      Tween<double>(begin: _popFrom, end: 1).chain(
        CurveTween(
          curve: const Interval(0.3, 0.8, curve: AppMotion.emphasized),
        ),
      );
  static final Animatable<double> _arrowFade = CurveTween(
    curve: const Interval(0.3, 0.8, curve: AppMotion.signature),
  );

  @override
  Widget build(BuildContext context) {
    final onSeeAll = this.onSeeAll;
    final reveal = HomeRevealScope.revealOf(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        HomeLayout.gutter,
        0,
        HomeLayout.gutter,
        AppSpacing.s12,
      ),
      child: Row(
        children: [
          if (!icon.isEmpty) ...[
            ScaleTransition(
              scale: reveal.drive(_iconPop),
              child: HomeIconView(
                icon: icon,
                size: AppSize.s20,
                color: HomeAccentPalette.strong(accent),
              ),
            ),
            const SizedBox(width: AppSpacing.s6),
          ],
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          if (onSeeAll != null) ...[
            const SizedBox(width: AppSpacing.s8),
            FadeTransition(
              opacity: reveal.drive(_arrowFade),
              child: ScaleTransition(
                scale: reveal.drive(_arrowPop),
                child: HomeArrowButton(
                  onTap: onSeeAll,
                  label: 'catalog.view_all'.tr(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
