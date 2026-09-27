import 'package:equatable/equatable.dart';

import '../../../../core/domain/localization/localized_pick.dart';
import 'support_order_line.dart';

/// The newest order, for the help center's "Get help with this order" card.
/// Carries the raw bilingual shop name and date; the card resolves them with
/// [shopNameFor] / [dateFor].
class SupportOrder extends Equatable {
  const SupportOrder({
    required this.id,
    required this.shopName,
    this.shopNameAr = '',
    required this.shopLogo,
    required this.total,
    required this.date,
    this.dateAr = '',
    this.lines = const <SupportOrderLine>[],
  });

  final String id;
  final String shopName;
  final String shopNameAr;
  final String shopLogo;

  /// KD.
  final double total;
  final String date;
  final String dateAr;
  final List<SupportOrderLine> lines;

  String shopNameFor(String languageCode) =>
      pickLocalized(languageCode, en: shopName, ar: shopNameAr);

  String dateFor(String languageCode) =>
      pickLocalized(languageCode, en: date, ar: dateAr);

  @override
  List<Object?> get props => [
    id,
    shopName,
    shopNameAr,
    shopLogo,
    total,
    date,
    dateAr,
    lines,
  ];
}
