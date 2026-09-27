import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../cubit/customer_service_cubit.dart';
import 'support_chat_button.dart';
import 'support_faq_list.dart';
import 'support_hotline_card.dart';
import 'support_recent_order_card.dart';
import 'support_search_help_field.dart';

/// The help-center hub: the recent-order help card, the search entry, the FAQ
/// topics, the hotline row and the chat-with-support button.
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
                if (order != null) SupportRecentOrderCard(order: order),
                const SupportSearchHelpField(),
                const SizedBox(height: AppSpacing.s8),
                SupportFaqList(faqs: state.faqs),
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
