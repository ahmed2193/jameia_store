import 'package:flutter/painting.dart';

import '../../core/domain/entities/order_status.dart';
import 'app_colors.dart';

/// The colours a status paints with: one source for the list chip, the
/// tracking header and anything else that shows a status.
abstract final class OrderStatusPalette {
  /// Text / icon colour of [status].
  static Color foreground(OrderStatus status) => switch (status.group) {
    OrderStatusGroup.inProgress => AppColors.primary,
    OrderStatusGroup.completed => AppColors.success,
    OrderStatusGroup.cancelled => AppColors.error,
  };

  /// Soft background behind [foreground].
  static Color background(OrderStatus status) => switch (status.group) {
    OrderStatusGroup.inProgress => AppColors.brandLightBg,
    OrderStatusGroup.completed => AppColors.successBg,
    OrderStatusGroup.cancelled => AppColors.errorBg,
  };
}
