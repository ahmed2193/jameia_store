import 'package:easy_localization/easy_localization.dart';

import '../../../../core/data/jameia_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../domain/entities/faq_item.dart';

/// Offline source for the customer-service help center. The live Jameia page hits
/// `/api/order` + `/api/faq/faqList`; here the recent order comes from the
/// in-memory [JameiaRepository] and the FAQ script is fixed (Jameia ships the same
/// help topics).
///
/// `.tr()` is resolved at call time (not cached) so each page open renders in
/// the current locale — matching the old page-scoped-cubit behavior.
abstract class SupportLocalDataSource {
  JameiaOrder? recentOrder();

  /// Rider off the first active order that has one; otherwise a generic rider so
  /// the IM chat still renders when no live order exists. (Moved out of the chat
  /// screen — the presentation no longer reaches into [JameiaRepository].)
  Rider activeRider();

  List<String> faqTopics();
  List<FaqItem> faqs();
}

class SupportLocalDataSourceImpl implements SupportLocalDataSource {
  SupportLocalDataSourceImpl(this.catalog);

  final JameiaRepository catalog;

  @override
  JameiaOrder? recentOrder() =>
      catalog.orders.isEmpty ? null : catalog.orders.first;

  @override
  Rider activeRider() {
    for (final o in catalog.orders) {
      if (o.rider != null) return o.rider!;
    }
    return const Rider(name: 'Rider', phone: '', vehicle: 'motorbike');
  }

  @override
  List<String> faqTopics() => [
    'support.faq_where_order_q'.tr(),
    'support.faq_refund_q'.tr(),
    'support.faq_missing_q'.tr(),
    'support.faq_address_q'.tr(),
    'support.faq_cancel_q'.tr(),
    'support.faq_payment_q'.tr(),
  ];

  @override
  List<FaqItem> faqs() => [
    FaqItem(
      question: 'support.faq_where_order_q'.tr(),
      answer: 'support.faq_where_order_a'.tr(),
    ),
    FaqItem(
      question: 'support.faq_refund_q'.tr(),
      answer: 'support.faq_refund_a'.tr(),
    ),
    FaqItem(
      question: 'support.faq_missing_q'.tr(),
      answer: 'support.faq_missing_a'.tr(),
    ),
    FaqItem(
      question: 'support.faq_address_q'.tr(),
      answer: 'support.faq_address_a'.tr(),
    ),
    FaqItem(
      question: 'support.faq_cancel_q'.tr(),
      answer: 'support.faq_cancel_a'.tr(),
    ),
    FaqItem(
      question: 'support.faq_payment_q'.tr(),
      answer: 'support.faq_payment_a'.tr(),
    ),
    FaqItem(
      question: 'support.faq_fees_q'.tr(),
      answer: 'support.faq_fees_a'.tr(),
    ),
    FaqItem(
      question: 'support.faq_contact_rider_q'.tr(),
      answer: 'support.faq_contact_rider_a'.tr(),
    ),
  ];
}
