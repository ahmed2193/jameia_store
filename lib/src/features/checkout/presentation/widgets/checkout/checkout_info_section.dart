import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/widgets/hero_list_row.dart';
import 'checkout_section.dart';

/// "Good to know": where Hero lists its guarantees, two plain links to the
/// store's own pages — the FAQ and the terms of service (`GET
/// /v1/pages/{slug}`, shown by the content page). No promise, refund or
/// guarantee is made here: the API backs none.
class CheckoutInfoSection extends StatelessWidget {
  const CheckoutInfoSection({super.key});

  /// CMS page slugs.
  static const String faqSlug = 'faq';
  static const String termsSlug = 'terms';

  @override
  Widget build(BuildContext context) {
    return CheckoutSection(
      title: 'checkout.info_title'.tr(),
      padding: EdgeInsetsDirectional.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          HeroListRow(
            dense: true,
            divider: true,
            icon: Icons.help_outline_rounded,
            title: 'checkout.info_faq'.tr(),
            subtitle: 'checkout.info_faq_sub'.tr(),
            onTap: () => context.push(Routes.contentPage, extra: faqSlug),
          ),
          HeroListRow(
            dense: true,
            icon: Icons.description_outlined,
            title: 'checkout.info_terms'.tr(),
            subtitle: 'checkout.info_terms_sub'.tr(),
            onTap: () => context.push(Routes.contentPage, extra: termsSlug),
          ),
        ],
      ),
    );
  }
}
