import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/navigation/navigation.dart';
import '../../domain/entities/home_bootstrap.dart';
import 'home_link_opener.dart';
import 'home_marketing_popup_view.dart';
import 'home_welcome_popup_view.dart';

/// Shows the due home popups one after the other: the first-order welcome
/// gift first when [welcome], then the marketing popups in backend order.
abstract final class HomePopupQueue {
  /// Tapping a call-to-action closes that popup and ends the queue: a
  /// marketing link leaves home (further popups would land on the wrong
  /// screen); the gift's "Order now" means the customer starts shopping here,
  /// and no campaign lands on top of that.
  static Future<void> show(
    BuildContext context, {
    required bool welcome,
    required List<HomeMarketingPopup> popups,
  }) async {
    if (welcome) {
      if (!context.mounted) return;
      final ordered = await showHeroDialog<bool>(
        context,
        barrierLabel: 'home.popup_barrier_label'.tr(),
        barrierColor: AppColors.popupScrim,
        pageBuilder: (dialogContext) => HomeWelcomePopupView(
          onOrderNow: () => dialogContext.pop(true),
          onClose: () => dialogContext.pop(false),
        ),
      );
      if (ordered ?? false) return;
      if (popups.isEmpty) return;
      await Future<void>.delayed(AppMotion.page);
    }
    for (final popup in popups) {
      if (!context.mounted) return;
      final followed = await showHeroDialog<bool>(
        context,
        barrierLabel: 'home.popup_barrier_label'.tr(),
        barrierColor: AppColors.popupScrim,
        pageBuilder: (dialogContext) => HomeMarketingPopupView(
          popup: popup,
          onClose: () => dialogContext.pop(false),
          onCta: () => dialogContext.pop(true),
        ),
      );
      if (!context.mounted) return;
      if (followed ?? false) {
        HomeLinkOpener.open(context, popup.link, title: popup.title);
        return;
      }
      // Let the closing transition finish before the next popup opens.
      await Future<void>.delayed(AppMotion.page);
    }
  }
}
