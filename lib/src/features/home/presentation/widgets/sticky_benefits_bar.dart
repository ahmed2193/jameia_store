import 'package:flutter/material.dart';

import '../../../../core/responsive/app_size.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../domain/entities/benefit_item_entity.dart';
import '../util/benefit_item_display.dart';

/// Jameia home benefits bar (`new_user_sticky` / `old_user_sticky`): a white
/// 36dp r10 pill listing benefit items — 18dp icon + 12dp medium colored label,
/// `#0000001A` 1×15 vertical separators between them.
class StickyBenefitsBar extends StatelessWidget {
  const StickyBenefitsBar({super.key, required this.benefits});

  final List<BenefitItemEntity> benefits;

  static IconData _icon(String name) => switch (name) {
    'bolt' => Icons.bolt,
    'verified' => Icons.verified_outlined,
    'savings' => Icons.savings_outlined,
    'shield' => Icons.shield_outlined,
    'gift' => Icons.card_giftcard,
    _ => Icons.local_offer_outlined,
  };

  @override
  Widget build(BuildContext context) {
    if (benefits.isEmpty) return const SizedBox.shrink();
    final children = <Widget>[];
    for (var i = 0; i < benefits.length; i++) {
      if (i > 0) {
        children.add(
          Container(
            margin: const EdgeInsetsDirectional.symmetric(horizontal: 7),
            width: 1,
            height: 15,
            color: AppColors.shadowInk10,
          ),
        );
      }
      children.add(Flexible(child: _Benefit(item: benefits[i])));
    }
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.pageMargin,
        0,
        AppSpacing.pageMargin,
        AppSpacing.s12,
      ),
      height: 36,
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r5),
        border: Border.all(color: AppColors.overlayDivider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.item});
  final BenefitItemEntity item;

  @override
  Widget build(BuildContext context) {
    final color = hexColor(item.color, AppColors.finalPrice);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(StickyBenefitsBar._icon(item.icon), size: 16, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            item.displayText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppSize.font12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
