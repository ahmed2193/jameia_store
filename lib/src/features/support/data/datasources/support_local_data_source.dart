import '../../../../core/data/hero_repository.dart';
import '../../../../core/data/models/models.dart';
import '../models/faq_model.dart';

/// Offline source for the customer-service help center. The live Hero page
/// hits `/api/order` + `/api/faq/faqList`; here the recent order comes from the
/// in-memory [HeroRepository] and the FAQ script is fixed (Hero ships the
/// same help topics). FAQ entries are i18n keys; the widgets resolve them.
abstract class SupportLocalDataSource {
  HeroOrder? recentOrder();

  /// Name of the rider of the first order that has one, `null` when none.
  String? activeRiderName();

  List<FaqModel> faqs();
}

class SupportLocalDataSourceImpl implements SupportLocalDataSource {
  const SupportLocalDataSourceImpl(this._catalog);

  final HeroRepository _catalog;

  @override
  HeroOrder? recentOrder() =>
      _catalog.orders.isEmpty ? null : _catalog.orders.first;

  @override
  String? activeRiderName() {
    for (final order in _catalog.orders) {
      final rider = order.rider;
      if (rider != null) return rider.name;
    }
    return null;
  }

  @override
  List<FaqModel> faqs() => const <FaqModel>[
    FaqModel(
      questionKey: 'support.faq_where_order_q',
      answerKey: 'support.faq_where_order_a',
    ),
    FaqModel(
      questionKey: 'support.faq_refund_q',
      answerKey: 'support.faq_refund_a',
    ),
    FaqModel(
      questionKey: 'support.faq_missing_q',
      answerKey: 'support.faq_missing_a',
    ),
    FaqModel(
      questionKey: 'support.faq_address_q',
      answerKey: 'support.faq_address_a',
    ),
    FaqModel(
      questionKey: 'support.faq_cancel_q',
      answerKey: 'support.faq_cancel_a',
    ),
    FaqModel(
      questionKey: 'support.faq_payment_q',
      answerKey: 'support.faq_payment_a',
    ),
    FaqModel(
      questionKey: 'support.faq_fees_q',
      answerKey: 'support.faq_fees_a',
    ),
    FaqModel(
      questionKey: 'support.faq_contact_rider_q',
      answerKey: 'support.faq_contact_rider_a',
    ),
  ];
}
