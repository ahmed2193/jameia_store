import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/customer_service_cubit.dart';

/// KeeTa customer-service help-center hub — `mach_pro_sailor_c_customer_service`.
///
/// Faithful 1:1 clone of KeeTa's Help-center surface (per analysis 2.11): a
/// recent-order help card (`order_default` → "Get help with this order"), a
/// search-help entry, a scripted FAQ list with chevrons (→
/// `customer_service_question`), a hotline call row (`hotlinePhone` /
/// `callPhone`), and a chat-with-support CTA (`kefu` IM entry).
///
/// Page-scoped cubit built inline (not registered in the service locator), per
/// the project's BlocProvider convention.
class CustomerServiceScreen extends StatelessWidget {
  const CustomerServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CustomerServiceCubit(sl<KeetaRepository>()),
      child: const _CustomerServiceView(),
    );
  }
}

class _CustomerServiceView extends StatelessWidget {
  const _CustomerServiceView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(KeetaIcons.back,
              size: 20, color: AppColors.primaryText),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Customer service',
            style: AppTextStyles.headingLarge
                .copyWith(fontWeight: AppTextStyles.bold)),
      ),
      body: BlocBuilder<CustomerServiceCubit, CustomerServiceState>(
        builder: (context, state) {
          return SafeArea(
            top: false,
            child: ContentClamp(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.s12),
                children: [
                  if (state.recentOrder != null)
                    _RecentOrderCard(order: state.recentOrder!),
                  const _SearchHelpField(),
                  const SizedBox(height: AppSpacing.s8),
                  _FaqList(faqs: state.faqs),
                  const SizedBox(height: AppSpacing.s8),
                  const _HotlineCard(),
                  const SizedBox(height: AppSpacing.s12),
                  const _ChatSupportButton(),
                  const SizedBox(height: AppSpacing.s24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Section: card chrome ──────────────────────────────────────────────────────

/// Shared white rounded card used by the help-center sections.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12),
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      child: child,
    );
  }
}

// ── Section: recent-order help card ───────────────────────────────────────────

class _RecentOrderCard extends StatelessWidget {
  const _RecentOrderCard({required this.order});
  final KeetaOrder order;

  @override
  Widget build(BuildContext context) {
    final itemNames =
        order.items.map((i) => '${i.name} ×${i.qty}').join(', ');
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.s8),
      child: _SectionCard(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                KeetaImage.circle(url: order.shopLogo, size: 40),
                const SizedBox(width: AppSpacing.s10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        order.shopName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingMedium
                            .copyWith(fontWeight: AppTextStyles.bold),
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        order.date,
                        style: AppTextStyles.captionLarge
                            .copyWith(color: AppColors.tertiaryText),
                      ),
                    ],
                  ),
                ),
                Text(
                  Formatters.price(order.total),
                  style: AppTextStyles.headingMedium
                      .copyWith(fontWeight: AppTextStyles.bold),
                ),
              ],
            ),
            if (itemNames.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                itemNames,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.secondaryText),
              ),
            ],
            const SizedBox(height: AppSpacing.s12),
            AppButton(
              label: 'Get help with this order',
              height: 42,
              onPressed: () => Navigator.pushNamed(
                  context, Routes.customerServiceQuestion,
                  arguments: order.id),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section: search-help entry ────────────────────────────────────────────────

class _SearchHelpField extends StatelessWidget {
  const _SearchHelpField();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r3),
        onTap: () => Navigator.pushNamed(
            context, Routes.customerServiceQuestion),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s12, vertical: AppSpacing.s12),
          child: Row(
            children: [
              const Icon(KeetaIcons.search,
                  size: 20, color: AppColors.tertiaryText),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Text(
                  'Search for help',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.tertiaryText),
                ),
              ),
              const Icon(KeetaIcons.arrowRight,
                  size: 16, color: AppColors.disabledText),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section: FAQ list ─────────────────────────────────────────────────────────

class _FaqList extends StatelessWidget {
  const _FaqList({required this.faqs});
  final List<String> faqs;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsetsDirectional.only(
                start: AppSpacing.s12,
                top: AppSpacing.s12,
                bottom: AppSpacing.s4),
            child: _FaqHeader(),
          ),
          for (var i = 0; i < faqs.length; i++) ...[
            if (i != 0) const ThinDivider(indent: AppSpacing.s12),
            _FaqRow(question: faqs[i]),
          ],
        ],
      ),
    );
  }
}

class _FaqHeader extends StatelessWidget {
  const _FaqHeader();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Frequently asked',
      style: AppTextStyles.headingMedium
          .copyWith(fontWeight: AppTextStyles.bold),
    );
  }
}

class _FaqRow extends StatelessWidget {
  const _FaqRow({required this.question});
  final String question;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(
          context, Routes.customerServiceQuestion,
          arguments: question),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s12, vertical: AppSpacing.s14),
        child: Row(
          children: [
            const Icon(KeetaIcons.help,
                size: 18, color: AppColors.secondaryText),
            const SizedBox(width: AppSpacing.s10),
            Expanded(
              child: Text(question, style: AppTextStyles.headingSmall),
            ),
            const Icon(KeetaIcons.arrowRight,
                size: 16, color: AppColors.disabledText),
          ],
        ),
      ),
    );
  }
}

// ── Section: hotline call row ─────────────────────────────────────────────────

class _HotlineCard extends StatelessWidget {
  const _HotlineCard();

  /// KeeTa `hotlinePhone` — wired to `callPhone` in the real page; here a
  /// scripted snackbar stands in (offline clone has no dialer bridge).
  static const String _hotline = '+965 2222 0000';

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r3),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Calling hotline $_hotline')),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s12, vertical: AppSpacing.s14),
          child: Row(
            children: [
              const Icon(KeetaIcons.phone,
                  size: 20, color: AppColors.success),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Call hotline',
                        style: AppTextStyles.headingSmall),
                    const SizedBox(height: AppSpacing.s2),
                    Text(_hotline,
                        style: AppTextStyles.captionLarge
                            .copyWith(color: AppColors.tertiaryText)),
                  ],
                ),
              ),
              const Icon(KeetaIcons.arrowRight,
                  size: 16, color: AppColors.disabledText),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section: chat-with-support CTA ────────────────────────────────────────────

class _ChatSupportButton extends StatelessWidget {
  const _ChatSupportButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12),
      child: AppButton(
        label: 'Chat with support',
        trailing: const Icon(KeetaIcons.chat,
            size: 18, color: AppColors.brandForeground),
        onPressed: () => Navigator.pushNamed(context, Routes.imChat),
      ),
    );
  }
}
