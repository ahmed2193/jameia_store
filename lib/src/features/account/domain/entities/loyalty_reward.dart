import 'package:equatable/equatable.dart';

import 'loyalty_program.dart';

/// One redemption tier on the Rewards screen: spend [points] for a basket
/// discount worth [valueFils] (`POST /v1/cart/loyalty {points}`).
class LoyaltyReward extends Equatable {
  const LoyaltyReward({required this.points, required this.valueFils});

  final int points;

  /// The discount the points buy, in fils.
  final int valueFils;

  /// The discount in dinar (1 fils → 0.001).
  double get valueKd => valueFils / LoyaltyProgram.filsPerDinar;

  @override
  List<Object?> get props => [points, valueFils];
}
