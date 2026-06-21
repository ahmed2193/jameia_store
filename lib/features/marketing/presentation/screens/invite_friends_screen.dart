import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/invite_friends_cubit.dart';

/// KeeTa Invite-friends / referral screen (`mkt_invite_main`).
///
/// Faithful 1:1 clone of the KeeTa referral flow: brand-yellow hero banner with
/// the "Invite friends, get KD off" headline, a referral-code box with a Copy
/// affordance, a numbered three-step "how it works" list, a big share CTA, and a
/// rewards-earned summary card (all dummy data via [KeetaRepository]).
class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InviteFriendsCubit(sl<KeetaRepository>()),
      child: const _InviteFriendsView(),
    );
  }
}

class _InviteFriendsView extends StatelessWidget {
  const _InviteFriendsView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InviteFriendsCubit>();
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(KeetaIcons.back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Invite friends',
          style: AppTextStyles.headingMedium
              .copyWith(fontWeight: AppTextStyles.bold),
        ),
        centerTitle: false,
      ),
      body: ContentClamp(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _HeroBanner(reward: cubit.rewardPerFriend),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.secondaryModule),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReferralCodeBox(code: cubit.referralCode),
                    const SizedBox(height: AppSpacing.s24),
                    const _StepsList(),
                    const SizedBox(height: AppSpacing.s24),
                    _RewardsSummary(
                      friendsJoined: cubit.friendsJoined,
                      totalEarned: cubit.totalEarned,
                      pendingEarned: cubit.pendingEarned,
                    ),
                    const SizedBox(height: AppSpacing.s24),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
      bottomNavigationBar: const _ShareBar(),
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.secondaryModule,
        AppSpacing.s8,
        AppSpacing.secondaryModule,
        AppSpacing.s32,
      ).resolve(Directionality.of(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _GiftBadge(),
          const SizedBox(height: AppSpacing.secondaryModule),
          Text(
            'Invite friends,\nget ${Formatters.price(reward)} off',
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.black,
              fontWeight: AppTextStyles.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Share your code. Your friend gets a welcome discount, '
            'and you earn credit on their first order.',
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
      child: const Icon(KeetaIcons.reward, size: 34, color: AppColors.black),
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
            'Your referral code',
            style: AppTextStyles.captionLarge
                .copyWith(color: AppColors.tertiaryText),
          ),
          const SizedBox(height: AppSpacing.s8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  alignment: AlignmentDirectional.centerStart,
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
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
              const _CopyButton(),
            ],
          ),
        ],
      ),
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InviteFriendsCubit, InviteFriendsState>(
      buildWhen: (a, b) => a.copied != b.copied,
      builder: (context, state) {
        final cubit = context.read<InviteFriendsCubit>();
        return Material(
          color: state.copied ? AppColors.success : AppColors.black,
          borderRadius: BorderRadius.circular(AppRadius.r5),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.r5),
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: cubit.referralCode));
              cubit.markCopied();
              await Future<void>.delayed(AppMotion.sheetLarge);
              cubit.resetCopied();
            },
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 18, vertical: 13),
              child: AnimatedSwitcher(
                duration: AppMotion.fast,
                child: Row(
                  key: ValueKey<bool>(state.copied),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      state.copied ? Icons.check_rounded : Icons.copy_rounded,
                      size: 16,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: AppSpacing.s6),
                    Text(
                      state.copied ? 'Copied' : 'Copy',
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
            'How it works',
            style: AppTextStyles.headingMedium
                .copyWith(fontWeight: AppTextStyles.bold),
          ),
          const SizedBox(height: AppSpacing.s16),
          const _StepRow(
            index: 1,
            icon: KeetaIcons.share,
            title: 'Share your code',
            subtitle: 'Send your code to friends via any app.',
          ),
          const _StepRow(
            index: 2,
            icon: KeetaIcons.cart,
            title: 'Friend places an order',
            subtitle: 'They get a welcome discount on their first order.',
          ),
          const _StepRow(
            index: 3,
            icon: KeetaIcons.reward,
            title: 'You earn credit',
            subtitle: 'Reward lands in your wallet after delivery.',
            last: true,
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
    required this.title,
    required this.subtitle,
    this.last = false,
  });

  final int index;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: last ? 0 : AppSpacing.secondaryModule),
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
            child: Icon(icon, size: 18, color: AppColors.black),
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
                        style: AppTextStyles.headingSmall
                            .copyWith(fontWeight: AppTextStyles.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.secondaryText),
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.black,
        borderRadius: BorderRadius.circular(AppRadius.r4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your rewards',
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
                  label: 'Friends joined',
                ),
              ),
              Container(width: 1, height: 38, color: AppColors.secondaryText),
              Expanded(
                child: _SummaryStat(
                  value: Formatters.price(totalEarned),
                  label: 'Total earned',
                  highlight: true,
                ),
              ),
              Container(width: 1, height: 38, color: AppColors.secondaryText),
              Expanded(
                child: _SummaryStat(
                  value: Formatters.price(pendingEarned),
                  label: 'Pending',
                ),
              ),
            ],
          ),
        ],
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
          style: AppTextStyles.captionSmall
              .copyWith(color: AppColors.tertiaryText),
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
    final cubit = context.read<InviteFriendsCubit>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: AppButton(
          label: 'Share invite',
          trailing: const Icon(KeetaIcons.share, size: 18, color: AppColors.black),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: cubit.referralCode));
            cubit.markCopied();
            await Future<void>.delayed(AppMotion.sheetLarge);
            cubit.resetCopied();
          },
        ),
      ),
    );
  }
}
