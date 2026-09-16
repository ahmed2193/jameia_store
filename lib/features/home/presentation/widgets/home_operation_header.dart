import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_assets.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// KeeTa home operation header as a COLLAPSING pinned [SliverAppBar].
///
/// Expanded (at the top): backdrop + address row + full rounded search pill.
/// As the page scrolls up the bar shrinks to a short pinned bar showing just the
/// address + a search **icon** (the pill fades/collapses, the icon grows in) —
/// keeping the docked bar compact.
///
/// `SliverAppBar` owns the status-bar inset + pinned geometry (avoids the
/// `layoutExtent exceeds paintExtent` assertion of a hand-rolled header).
Widget homeHeaderSliver({
  required KeetaAddress address,
  required double topPad,
  VoidCallback? onAddressTap,
}) {
  const collapsed = 48.0; // compact bar height below the status bar
  const expandedContent = 104.0; // top6 + address34 + gap8 + pill46 + slack
  final expandedHeight = topPad + expandedContent;

  return SliverAppBar(
    pinned: true,
    automaticallyImplyLeading: false,
    backgroundColor: AppColors.mediumBackground,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    toolbarHeight: collapsed,
    collapsedHeight: collapsed,
    expandedHeight: expandedHeight,
    flexibleSpace: LayoutBuilder(
      builder: (context, constraints) {
        final minH = topPad + collapsed;
        // t = 1 fully expanded · 0 fully collapsed.
        final t = ((constraints.maxHeight - minH) / (expandedHeight - minH))
            .clamp(0.0, 1.0);
        return Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop fades out as the bar collapses → clean solid compact bar.
            Opacity(
              opacity: t,
              child: Image.asset(
                KeetaAssets.homeHeaderDefaultBg,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.primary, AppColors.mediumBackground],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.only(
                top: topPad + 6,
                start: AppSpacing.pageMargin,
                end: AppSpacing.pageMargin,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address + (collapsed) search icon + bell.
                  SizedBox(
                    height: 34,
                    child: Row(
                      children: [
                        Expanded(
                          child: _AddressGroup(
                            address: address,
                            onTap: onAddressTap,
                          ),
                        ),
                        // Search icon grows in as the pill collapses.
                        ClipRect(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            widthFactor: (1 - t),
                            child: Opacity(
                              opacity: (1 - t),
                              child: const _SearchIconButton(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const _Bell(),
                      ],
                    ),
                  ),
                  // Full search pill — collapses (height + opacity) as t → 0.
                  ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: t,
                      child: Opacity(
                        opacity: t,
                        child: const Padding(
                          padding: EdgeInsetsDirectional.only(
                            top: AppSpacing.s8,
                          ),
                          child: _SearchPill(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// Tappable address group (location icon + label + chevron) → address flow.
class _AddressGroup extends StatelessWidget {
  const _AddressGroup({required this.address, this.onTap});
  final KeetaAddress address;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Image.asset(
            KeetaAssets.addressLocationV3,
            width: 18,
            height: 18,
            errorBuilder: (_, _, _) => const Icon(
              KeetaIcons.location,
              size: 18,
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${address.label} · ${address.area}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: AppSize.font16,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Image.asset(
            KeetaAssets.addressDownV3,
            width: 16,
            height: 16,
            errorBuilder: (_, _, _) => const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Notification bell (32dp tile).
class _Bell extends StatelessWidget {
  const _Bell();
  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: AppColors.black.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(AppRadius.r5),
    ),
    alignment: Alignment.center,
    child: const Icon(
      Icons.notifications_none_rounded,
      size: 20,
      color: AppColors.black,
    ),
  );
}

/// Compact search affordance shown in the collapsed bar.
class _SearchIconButton extends StatelessWidget {
  const _SearchIconButton();
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, Routes.search),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 32,
        alignment: Alignment.center,
        child: Image.asset(
          KeetaAssets.searchBlack,
          width: 20,
          height: 20,
          errorBuilder: (_, _, _) => const Icon(
            KeetaIcons.search,
            size: 20,
            color: AppColors.primaryText,
          ),
        ),
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  const _SearchPill();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, Routes.search),
      borderRadius: BorderRadius.circular(AppSize.r23),
      child: Container(
        height: 46,
        padding: const EdgeInsetsDirectional.only(start: 16, end: 12),
        decoration: BoxDecoration(
          color: AppColors.smallBackground,
          borderRadius: BorderRadius.circular(AppSize.r23),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        child: Row(
          children: [
            Image.asset(
              KeetaAssets.searchBlack,
              width: 16,
              height: 16,
              errorBuilder: (_, _, _) => const Icon(
                KeetaIcons.search,
                size: 16,
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'home.search_shops_dishes'.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppSize.font14,
                  color: AppColors.searchHintInk,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
