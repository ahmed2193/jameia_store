import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/motion/size_fade_switcher.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../cubit/customer_service_cubit.dart';
import 'support_chat_button.dart';
import 'support_faq_list.dart';
import 'support_faq_pending.dart';
import 'support_hotline_card.dart';
import 'support_recent_order_card.dart';
import 'support_search_help_field.dart';

/// The help-center hub: the recent-order help card, the search entry, the FAQ
/// topics, the hotline row and the chat-with-support button. The order card
/// arrives after the page: it opens its room ([CollapseReveal]) instead of
/// snapping in and shoving the hub down, and the rows below keep their
/// elements (no entrance replays). The topics card shows the dots while they
/// load and a Retry when they did not, easing into the list (one height
/// move, [SizeFadeSwitcher]); the hotline and chat stay usable meanwhile.
class CustomerServiceBody extends StatelessWidget {
  const CustomerServiceBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerServiceCubit, CustomerServiceState>(
      builder: (context, state) {
        final order = state.recentOrder;
        return SafeArea(
          top: false,
          child: ContentClamp(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
              children: [
                CollapseReveal(
                  visible: order != null,
                  child: order == null
                      ? const SizedBox.shrink()
                      : SupportRecentOrderCard(order: order),
                ),
                const SupportSearchHelpField(),
                const SizedBox(height: AppSpacing.s8),
                SizeFadeSwitcher(
                  stateKey: state.status == CustomerServiceStatus.initial
                      ? CustomerServiceStatus.loading
                      : state.status,
                  child: switch (state.status) {
                    CustomerServiceStatus.loaded => SupportFaqList(
                      faqs: state.faqs,
                    ),
                    CustomerServiceStatus.error => SupportFaqPending(
                      errorMessage: state.errorMessage,
                      onRetry: context.read<CustomerServiceCubit>().load,
                    ),
                    _ => const SupportFaqPending(),
                  },
                ),
                const SizedBox(height: AppSpacing.s8),
                const SupportHotlineCard(),
                const SizedBox(height: AppSpacing.s12),
                const SupportChatButton(),
                const SizedBox(height: AppSpacing.s24),
              ],
            ),
          ),
        );
      },
    );
  }
}
