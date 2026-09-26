import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/widgets/branded_refresh.dart';
import '../cubit/pro_brands_cubit.dart';
import '../cubit/pro_membership_cubit.dart';
import 'pro_bottom_bar.dart';
import 'pro_delivery_section.dart';
import 'pro_greeting_card.dart';
import 'pro_hero_band.dart';
import 'pro_keep_alive.dart';
import 'pro_perk_cards.dart';
import 'pro_plan_tabs.dart';

/// The loaded paywall: plan tabs, the plan's hero, the greeting / price card,
/// the free-delivery band and the perk cards scroll (pull to refresh) under
/// the floating account strip + CTA. `extendBody` lets the content run
/// behind the bar and hands the list the bar's height as bottom padding, so
/// nothing ends up hidden under it. Every section reads its own slice of the
/// state, so switching plans rebuilds only what shows the plan. The top
/// sections stay alive when the list scrolls far past them, so their
/// entrances play once, not again on the way back up.
class ProPaywallView extends StatelessWidget {
  const ProPaywallView({super.key});

  Future<void> _refresh(BuildContext context) async {
    final membership = context.read<ProMembershipCubit>();
    final brands = context.read<ProBrandsCubit>();
    await Future.wait([membership.refresh(), brands.load()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      extendBody: true,
      body: BrandedRefresh(
        onRefresh: () => _refresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            ProKeepAlive(child: ProPlanTabs()),
            ProKeepAlive(child: ProHeroBand()),
            SizedBox(height: AppSpacing.s16),
            ProKeepAlive(child: ProGreetingCard()),
            ProDeliverySection(),
            ProPerkCards(),
            SizedBox(height: AppSpacing.s32),
          ],
        ),
      ),
      bottomNavigationBar: const ProBottomBar(),
    );
  }
}
