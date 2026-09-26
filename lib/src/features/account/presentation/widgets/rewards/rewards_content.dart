import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../domain/entities/loyalty_rewards.dart';
import '../../cubit/loyalty_rewards_cubit.dart';
import 'rewards_balance_header.dart';
import 'rewards_grid.dart';
import 'rewards_section_title.dart';

/// The loaded Rewards screen as a pull-to-refresh scroll: the balance, then
/// the tiers the balance covers and the ones still out of reach (a section
/// only when it has tiers). A tier applied from here bursts warm confetti
/// over the page.
class RewardsContent extends StatefulWidget {
  const RewardsContent({super.key, required this.rewards});

  final LoyaltyRewards rewards;

  @override
  State<RewardsContent> createState() => _RewardsContentState();
}

class _RewardsContentState extends State<RewardsContent> {
  static const List<Color> _confetti = [
    AppColors.proAmber,
    AppColors.accent3,
    kJameiaPillPin,
    AppColors.proLime,
  ];

  /// Bumped by every tier applied from this screen; each bump is a burst.
  final ValueNotifier<int> _celebrations = ValueNotifier<int>(0);

  void _celebrate() => _celebrations.value++;

  @override
  void dispose() {
    _celebrations.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rewards = widget.rewards;
    final ready = rewards.ready;
    final locked = rewards.locked;
    return ValueListenableBuilder<int>(
      valueListenable: _celebrations,
      builder: (_, bursts, page) => ConfettiBurst(
        playKey: bursts == 0 ? null : bursts,
        colors: _confetti,
        child: page!,
      ),
      child: BrandedRefresh(
        onRefresh: () => context.read<LoyaltyRewardsCubit>().refresh(),
        child: ContentClamp(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: RewardsBalanceHeader(rewards: rewards)),
              if (ready.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: RewardsSectionTitle('loyalty.rewards_ready'.tr()),
                ),
                RewardsGrid(
                  items: ready,
                  rewards: rewards,
                  firstIndex: 0,
                  onRedeemed: _celebrate,
                ),
              ],
              if (locked.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: RewardsSectionTitle('loyalty.rewards_locked'.tr()),
                ),
                RewardsGrid(
                  items: locked,
                  rewards: rewards,
                  firstIndex: ready.length,
                  onRedeemed: _celebrate,
                ),
              ],
              SliverPadding(
                padding: EdgeInsetsDirectional.only(
                  bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.s24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
