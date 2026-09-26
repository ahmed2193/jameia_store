import 'package:flutter/material.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import 'home_eta_pill.dart';
import 'home_pro_badge.dart';
import 'home_store_logo.dart';

/// Who is delivering: the store badge, the "pro" tag and the store name, and
/// the delivery pill under them once the zone's ETA is known.
class HomeStoreIdentity extends StatelessWidget {
  const HomeStoreIdentity({
    super.key,
    required this.storeName,
    required this.isPro,
    required this.etaMinutes,
  });

  final String storeName;
  final bool isPro;

  /// `0` while the ETA is unknown: no pill, the name centres on the badge.
  final int etaMinutes;

  /// Room between the name and the pill.
  static const double lineGap = AppSpacing.s4;

  /// Line height of the store name before the reader's text scale.
  static const double _nameLine = AppSize.s24;

  /// The height the identity takes at [textScaler] — with the pill, so the
  /// header does not grow when the ETA lands.
  static double heightFor(TextScaler textScaler) {
    final text =
        textScaler.scale(_nameLine) +
        lineGap +
        HomeEtaPill.heightFor(textScaler);
    return text > HomeStoreLogo.size ? text : HomeStoreLogo.size;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Row(
        children: [
          const HomeStoreLogo(),
          const SizedBox(width: AppSpacing.s10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isPro) ...[
                      const HomeProBadge(),
                      const SizedBox(width: AppSpacing.s6),
                    ],
                    Flexible(
                      child: Text(
                        storeName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingLarge.copyWith(
                          fontWeight: AppTextStyles.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (etaMinutes > 0) ...[
                  const SizedBox(height: lineGap),
                  HomeEtaPill(minutes: etaMinutes),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
