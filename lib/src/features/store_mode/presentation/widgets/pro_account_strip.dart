import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/login_args.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../auth/presentation/cubit/auth_session_cubit.dart';
import 'pro_outlined_badge.dart';
import 'pro_underlined_link.dart';

/// Pro-gradient strip above the CTA, its rounded top floating over the
/// content: a guest is invited to sign in (`go`, so the page is rebuilt for
/// the new session, then reopened once signed in); a customer sees their
/// points (at once on open; only the number rolls on a real change) and a
/// link to the rewards they can redeem them for.
class ProAccountStrip extends StatelessWidget {
  const ProAccountStrip({super.key});

  static const double _minHeight = AppSize.s56;

  static const BoxDecoration _decoration = BoxDecoration(
    gradient: LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: AppColors.proGradient,
    ),
    borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r2)),
  );

  @override
  Widget build(BuildContext context) {
    final signedIn = context.select<AuthSessionCubit, bool>(
      (cubit) => cubit.state.isSignedIn,
    );
    final points = context.select<AuthSessionCubit, int>(
      (cubit) => cubit.state.customer?.loyaltyPoints ?? 0,
    );
    final style = AppTextStyles.subheadingLarge.copyWith(
      color: AppColors.white,
    );
    return Container(
      constraints: const BoxConstraints(minHeight: _minHeight),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s8,
      ),
      decoration: _decoration,
      child: Row(
        children: [
          const ProOutlinedBadge(),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: signedIn
                ? RollingNumberText(
                    value: points,
                    text: (number) =>
                        'pro.strip_points'.tr(namedArgs: {'points': number}),
                    style: style,
                  )
                : Text('pro.strip_guest'.tr(), style: style),
          ),
          const SizedBox(width: AppSpacing.s8),
          ProUnderlinedLink(
            label: signedIn
                ? 'pro.strip_rewards'.tr()
                : 'pro.strip_sign_in'.tr(),
            color: AppColors.white,
            style: AppTextStyles.subheadingLarge,
            onTap: signedIn
                ? () => context.push(Routes.loyaltyRewards)
                : () => context.go(
                    Routes.login,
                    extra: const LoginArgs(returnTo: Routes.proMembership),
                  ),
          ),
        ],
      ),
    );
  }
}
