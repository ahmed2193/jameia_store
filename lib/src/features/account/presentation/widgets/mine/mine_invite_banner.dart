import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/light_sweep.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import 'mine_gift_badge.dart';

/// Invite / referral banner: a cream → white card with the warm gift badge,
/// title, pitch and a chevron → invite friends. For everyone but a Pro
/// member (whose PRO pill carries the tab's one shine) a slow light sweep
/// crosses it while the tab is on screen.
class MineInviteBanner extends StatelessWidget {
  const MineInviteBanner({super.key});

  static const double _chevron = AppSize.s16;
  static final BorderRadius _radius = BorderRadius.circular(AppRadius.r3);

  @override
  Widget build(BuildContext context) {
    final isPro = context.select<AuthSessionCubit, bool>(
      (session) =>
          session.state.isSignedIn && (session.state.customer?.isPro ?? false),
    );
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
      ),
      child: Semantics(
        button: true,
        child: PressScale(
          onTap: () => context.push(Routes.inviteFriends),
          child: LightSweep(
            active: !isPro,
            borderRadius: _radius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                  colors: [AppColors.accent4Light, AppColors.white],
                ),
                borderRadius: _radius,
                border: Border.all(color: AppColors.overlayDivider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s12),
                child: Row(
                  children: [
                    const MineGiftBadge(),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'account.invite_title'.tr(),
                            style: AppTextStyles.headingSmall.copyWith(
                              fontWeight: AppTextStyles.bold,
                              color: AppColors.primaryText,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.s2),
                          Text(
                            'account.invite_subtitle'.tr(),
                            style: AppTextStyles.captionLarge.copyWith(
                              color: AppColors.labelGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    const HeroIcon(
                      HeroIcons.chevronEnd,
                      size: _chevron,
                      color: AppColors.tertiaryText,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
