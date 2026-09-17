import 'package:equatable/equatable.dart';

import '../localization/localized_pick.dart';

/// One line of a placed order (name × qty @ price).
class OrderItemEntity extends Equatable {
  const OrderItemEntity({
    required this.name,
    this.nameAr = '',
    required this.qty,
    required this.price,
  });

  /// English / default name.
  final String name;

  /// Arabic name ('' when absent).
  final String nameAr;
  final int qty;
  final double price;

  /// Active-locale item name: Arabic when [languageCode] is `ar*` and [nameAr]
  /// is non-blank, else [name].
  String nameFor(String languageCode) =>
      pickLocalized(languageCode, en: name, ar: nameAr);

  @override
  List<Object?> get props => [name, nameAr, qty, price];
}
