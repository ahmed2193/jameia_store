import 'package:equatable/equatable.dart';

/// Framework-free sticky-benefits-bar item entity.
///
/// Source stores Arabic/default in [text], English in [textEn]; the
/// active-locale pick lives in `presentation/util/benefit_item_display.dart`.
/// Hex colour stays a string.
class BenefitItemEntity extends Equatable {
  const BenefitItemEntity({
    required this.text,
    this.textEn = '',
    this.icon = 'bolt',
    this.color = '#F0390E',
  });

  final String text; // Arabic / default
  final String textEn; // English counterpart
  final String icon; // material icon name (mapped in widget)
  final String color; // hex

  @override
  List<Object?> get props => [text, textEn, icon, color];
}
