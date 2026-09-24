import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/navigation/navigation.dart';
import '../../domain/entities/home_bootstrap.dart';
import 'home_link_opener.dart';
import 'home_marketing_popup_view.dart';

/// Shows the due marketing popups one after the other, in backend order.
abstract final class HomePopupQueue {
  /// Tapping a call-to-action closes that popup, opens its link and ends the
  /// queue: the customer has left home, further popups would land on the
  /// wrong screen.
  static Future<void> show(
    BuildContext context,
    List<HomeMarketingPopup> popups,
  ) async {
    for (final popup in popups) {
      if (!context.mounted) return;
      final followed = await showJameiaDialog<bool>(
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
