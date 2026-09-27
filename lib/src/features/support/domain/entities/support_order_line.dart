import 'package:equatable/equatable.dart';

import '../../../../core/domain/localization/localized_pick.dart';

/// One line of a [SupportOrder]: the product name and how many were ordered.
class SupportOrderLine extends Equatable {
  const SupportOrderLine({
    required this.name,
    this.nameAr = '',
    required this.qty,
  });

  final String name;
  final String nameAr;
  final int qty;

  String nameFor(String languageCode) =>
      pickLocalized(languageCode, en: name, ar: nameAr);

  @override
  List<Object?> get props => [name, nameAr, qty];
}
