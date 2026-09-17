import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/design/jameia_assets.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/marketing_moments.dart';
import '../../domain/entities/invite_friends.dart';
import '../cubit/invite_friends_cubit.dart';

/// Jameia Invite-friends / referral screen (`mkt_invite_main`).
///
/// Faithful 1:1 clone of the Jameia referral flow: brand-yellow hero banner with
/// the "Invite friends, get KD off" headline, a referral-code box with a Copy
/// affordance, a numbered three-step "how it works" list, a big share CTA, and a
/// rewards-earned summary card (all dummy data via [InviteFriendsCubit]).
class InviteFriendsPage extends StatelessWidget {
  const InviteFriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<InviteFriendsCubit>(),
      child: const _InviteFriendsView(),
    );
  }
}

class _InviteFriendsView extends StatelessWidget {
  const _InviteFriendsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(JameiaIcons.back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'marketing.app_bar_title'.tr(),
          style: AppTextStyles.headingMedium.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocBuilder<InviteFriendsCubit, InviteFriendsState>(
        // Only swap between the top-level loading/error/loaded variants here;
        // the "copied" affordance rebuild is scoped to the copy button below.
        buildWhen: (a, b) => a.status != b.status || a.invite != b.invite,
        builder: (context, state) {
          if (state.status == InviteFriendsStatus.error) {
            return ErrorView(
              message: 'marketing.error_load'.tr(),
              onRetry: () => context.read<InviteFriendsCubit>().load(),
            );
          }
          final invite = state.invite;
          if (invite == null) return const AppLoader();
          return _InviteBody(invite: invite);
        },
      ),
      bottomNavigationBar: const _ShareBar(),
    );
  }
}

class _InviteBody extends StatelessWidget {
  const _InviteBody({required this.invite});
  final InviteFriends invite;

  @override
  Widget build(BuildContext context) {
    return ContentClamp(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _HeroBanner(reward: invite.rewardPerFriend),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.secondaryModule),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ReferralCodeBox(code: invite.referralCode),
                  const SizedBox(height: AppSpacing.s24),
                  const _StepsList(),
                  const SizedBox(height: AppSpacing.s24),
                  _RewardsSummary(
                    friendsJoined: invite.friendsJoined,
                    totalEarned: invite.totalEarned,
                    pendingEarned: invite.pendingEarned,
                  ),
                  const SizedBox(height: AppSpacing.s24),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 96)),
        ],
      ),
    );
  }
}

// ── Hero banner (brand yellow) ─────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.reward});
  final double reward;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.brandDarkBg],
        ),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.secondaryModule,
        AppSpacing.s8,
        AppSpacing.secondaryModule,
        AppSpacing.s32,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GiftBadge(),
          const SizedBox(height: AppSpacing.secondaryModule),
          Text(
            'marketing.hero_title'.tr(
              namedArgs: {'reward': Formatters.price(reward)},
            ),
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.black,
              fontWeight: AppTextStyles.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'marketing.hero_subtitle'.tr(),
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.black),
          ),
        ],
      ),
    );
  }
}

class _GiftBadge extends StatelessWidget {
  const _GiftBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
        boxShadow: const [
          BoxShadow(
            color: AppColors.overlayDivider,
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Image.asset(
          JameiaAssets.inviteRewardCommon,
          errorBuilder: (_, _, _) =>
              const Icon(JameiaIcons.reward, size: 34, color: AppColors.black),
        ),
      ),
    );
  }
}

// ── Referral-code box + Copy ───────────────────────────────────────────────────
class _ReferralCodeBox extends StatelessWidget {
  const _ReferralCodeBox({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r4),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'marketing.referral_code_label'.tr(),
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.tertiaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  alignment: AlignmentDirectional.centerStart,
                  padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandLightBg,
                    borderRadius: BorderRadius.circular(AppRadius.r5),
                    border: Border.all(color: AppColors.primary, width: 1.4),
                  ),
                  child: Text(
                    code,
                    style: AppTextStyles.headingLarge.copyWith(
                      fontWeight: AppTextStyles.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              _CopyButton(code: code),
            ],
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InviteFriendsCubit, InviteFriendsState>(
      buildWhen: (a, b) => a.copied != b.copied,
      builder: (context, state) {
        final cubit = context.read<InviteFriendsCubit>();
        // Press feel on the copy affordance; the InkWell keeps the tap + ripple
        // so PressScale stays passive.
        return PressScale(
          child: Material(
            color: state.copied ? AppColors.success : AppColors.black,
            borderRadius: BorderRadius.circular(AppRadius.r5),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.r5),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: code));
                cubit.markCopied();
                await Future<void>.delayed(AppMotion.sheetLarge);
                cubit.resetCopied();
              },
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                child: AnimatedSwitcher(
                  duration: MotionGuard.duration(context, AppMotion.fast),
                  switchInCurve: MotionGuard.curve(
                    context,
                    AppMotion.signature,
                  ),
                  switchOutCurve: MotionGuard.curve(context, AppMotion.exit),
                  child: Row(
                    key: ValueKey<bool>(state.copied),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.copied ? JameiaIcons.confirm : Icons.copy_rounded,
                        size: 16,
                        color: AppColors.white,
                      ),
                      const SizedBox(width: AppSpacing.s6),
                      Text(
                        state.copied
                            ? 'marketing.copied'.tr()
                            : 'marketing.copy'.tr(),
                        style: AppTextStyles.headingSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── How-it-works steps ─────────────────────────────────────────────────────────
class _StepsList extends StatelessWidget {
  const _StepsList();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r4),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'marketing.how_it_works'.tr(),
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          RepaintBoundary(
            child: StaggerEntrance(
              index: 0,
              child: _StepRow(
                index: 1,
                icon: JameiaIcons.share,
                asset: JameiaAssets.inviteWorkInvite,
                title: 'marketing.step_share_title'.tr(),
                subtitle: 'marketing.step_share_subtitle'.tr(),
              ),
            ),
          ),
          RepaintBoundary(
            child: StaggerEntrance(
              index: 1,
              child: _StepRow(
                index: 2,
                icon: JameiaIcons.cart,
                asset: JameiaAssets.inviteWorkOrder,
                title: 'marketing.step_order_title'.tr(),
                subtitle: 'marketing.step_order_subtitle'.tr(),
              ),
            ),
          ),
          RepaintBoundary(
            child: StaggerEntrance(
              index: 2,
              child: _StepRow(
                index: 3,
                icon: JameiaIcons.reward,
                asset: JameiaAssets.inviteWorkReward,
                title: 'marketing.step_reward_title'.tr(),
                subtitle: 'marketing.step_reward_subtitle'.tr(),
                last: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.icon,
    required this.asset,
    required this.title,
    required this.subtitle,
    this.last = false,
  });

  final int index;
  final IconData icon;
  final String asset;
  final String title;
  final String subtitle;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
        bottom: last ? 0 : AppSpacing.secondaryModule,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.brandLightBg,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              asset,
              width: 20,
              height: 20,
              errorBuilder: (_, _, _) =>
                  Icon(icon, size: 18, color: AppColors.black),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$index',
                        style: AppTextStyles.captionSmall.copyWith(
                          color: AppColors.white,
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: Text(
                        title,
                        style: AppTextStyles.headingSmall.copyWith(
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Rewards-earned summary ─────────────────────────────────────────────────────
class _RewardsSummary extends StatelessWidget {
  const _RewardsSummary({
    required this.friendsJoined,
    required this.totalEarned,
    required this.pendingEarned,
  });

  final int friendsJoined;
  final double totalEarned;
  final double pendingEarned;

  @override
  Widget build(BuildContext context) {
    // The summary card counts as an "earned/unlocked" reward once any credit has
    // landed — pop it in on unlock and sweep the brand shine across the art.
    final unlocked = totalEarned > 0;
    return PopScale(
      popKey: unlocked,
      child: ShineSweep(
        active: unlocked,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.black,
            borderRadius: BorderRadius.circular(AppRadius.r4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'marketing.your_rewards'.tr(),
                style: AppTextStyles.headingMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: AppTextStyles.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              Row(
                children: [
                  Expanded(
                    child: _SummaryStat(
                      value: '$friendsJoined',
                      label: 'marketing.stat_friends_joined'.tr(),
                    ),
                  ),
                  Container(width: 1, height: 14, color: AppColors.neutral[10]),
                  Expanded(
                    child: _SummaryStat(
                      value: Formatters.price(totalEarned),
                      label: 'marketing.stat_total_earned'.tr(),
                      highlight: true,
                    ),
                  ),
                  Container(width: 1, height: 14, color: AppColors.neutral[10]),
                  Expanded(
                    child: _SummaryStat(
                      value: Formatters.price(pendingEarned),
                      label: 'marketing.stat_pending'.tr(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.headingMedium.copyWith(
            color: highlight ? AppColors.primary : AppColors.white,
            fontWeight: AppTextStyles.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.captionSmall.copyWith(
            color: AppColors.tertiaryText,
          ),
        ),
      ],
    );
  }
}

// ── Sticky share CTA ───────────────────────────────────────────────────────────
class _ShareBar extends StatelessWidget {
  const _ShareBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: AppButton(
          label: 'marketing.share_invite'.tr(),
          trailing: const Icon(
            JameiaIcons.share,
            size: 18,
            color: AppColors.black,
          ),
          onPressed: () async {
            final cubit = context.read<InviteFriendsCubit>();
            final code = cubit.state.invite?.referralCode;
            if (code == null) return;
            await Clipboard.setData(ClipboardData(text: code));
            cubit.markCopied();
            await Future<void>.delayed(AppMotion.sheetLarge);
            cubit.resetCopied();
          },
        ),
      ),
    );
  }
}
