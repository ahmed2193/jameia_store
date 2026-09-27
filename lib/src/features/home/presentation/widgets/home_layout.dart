import 'package:flutter/painting.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/responsive/app_size.dart';

/// The rhythm of the home storefront: every block lines up on one gutter,
/// sits the same distance from the next, and rounds its corners the same way.
abstract final class HomeLayout {
  /// Side margin of every block — header, banners, rails and tile rows.
  static const double gutter = AppSpacing.s16;

  /// Room between two blocks of the feed.
  static const double blockGap = AppSpacing.s16;

  /// Room between two tiles or cards of a horizontal row.
  static const double itemGap = AppSpacing.s10;

  /// Corner radius of banners and tiles.
  static const double radius = AppSize.r14;

  /// The storefront accent: the delivery pill, the address pin, the tile
  /// hills and the minimum-order progress.
  static const Color accent = kHeroPillPin;
}
