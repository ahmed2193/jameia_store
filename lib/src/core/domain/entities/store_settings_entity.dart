import 'package:equatable/equatable.dart';

import 'vip_card_entity.dart';

/// Store settings relevant to the Jameia surfaces (mirrors the `JameiaSettings`
/// DTO): prep time, the order-again / best-selling rail toggles and the two
/// VIP / Mart hero cards.
class StoreSettingsEntity extends Equatable {
  const StoreSettingsEntity({
    this.prepTime = 0,
    this.displayOrderAgain = false,
    this.displayBestSelling = false,
    this.vip = const VipCardEntity(),
    this.mart = const VipCardEntity(),
  });

  /// Minutes — VIP/Mart "fast" card.
  final int prepTime;
  final bool displayOrderAgain;
  final bool displayBestSelling;
  final VipCardEntity vip;
  final VipCardEntity mart;

  @override
  List<Object?> get props => [
    prepTime,
    displayOrderAgain,
    displayBestSelling,
    vip,
    mart,
  ];
}
