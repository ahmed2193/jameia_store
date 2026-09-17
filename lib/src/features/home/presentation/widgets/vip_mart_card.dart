import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/jameia_assets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../store_mode/presentation/cubit/store_mode_cubit.dart';
import '../../domain/entities/store_settings_entity.dart';

/// VIP / Mart store-mode selector — ported 1:1 from jm3eia's `VipMartSection`.
///
/// Two Jameia-style promo cards:
///   • Jameia (Mart) — warm cream card, maroon title, orange "›", bag art.
///   • Fast delivery (VIP) — soft-pink card, maroon title, orange "›", a big
///     orange preparation-time number + scooter art.
/// The ACTIVE store mode's card carries a coloured outline + glow (Mart →
/// orange, VIP → red). Tapping the INACTIVE card flips the mode via [onToggle].
///
/// Rebuilds on the global `StoreModeCubit` `state.isVip` so the active outline
/// follows the current mode.
class VipMartCard extends StatelessWidget {
  const VipMartCard({
    super.key,
    required this.onToggle,
    required this.settings,
  });

  /// Called with the desired mode (`true` → VIP, `false` → Mart) when the user
  /// taps the inactive side. The host performs the toggle + cart clear.
  final ValueChanged<bool> onToggle;

  /// Store settings (prep time + hero-card content), sourced from `HomeState`.
  final StoreSettingsEntity settings;

  @override
  Widget build(BuildContext context) {
    final minutes = settings.prepTime > 0 ? settings.prepTime : 60;

    return BlocBuilder<StoreModeCubit, StoreModeState>(
      buildWhen: (a, b) => a.isVip != b.isVip,
      builder: (context, store) {
        final isVip = store.isVip;
        return Padding(
          // jm3eia `_metaBlock` padding: fromSTEB(md, xs, md, md).
          padding: const EdgeInsetsDirectional.fromSTEB(12, 4, 12, 12),
          child: RepaintBoundary(
            child: Row(
              children: [
                // ── Jameia (Mart) card ─────────────────────────────────────
                Expanded(
                  child: _PromoCard(
                    background: kJameiaPromoCream,
                    accent: kJameiaAccentMart,
                    active: !isVip,
                    title: settings.mart.title.isNotEmpty
                        ? settings.mart.title
                        : 'home.jameia'.tr(),
                    subtitle: settings.mart.desc.isNotEmpty
                        ? settings.mart.desc
                        : 'home.groceries_and_more'.tr(),
                    art: Image.asset(
                      JameiaAssets.jameiaBag,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                    onTap: () {
                      if (isVip) onToggle(false);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // ── Fast delivery (VIP) card ───────────────────────────────
                Expanded(
                  child: _PromoCard(
                    background: kJameiaPromoPink,
                    accent: kJameiaAccentVip,
                    active: isVip,
                    mirrorArtInRtl: true,
                    title: 'home.fast_delivery'.tr(),
                    subtitle: 'home.minutes'.tr(
                      namedArgs: {'minutes': '$minutes'},
                    ),
                    art: Image.asset(
                      JameiaAssets.jameiaScooter,
                      fit: BoxFit.contain,
                      alignment: AlignmentDirectional.bottomEnd,
                    ),
                    topEndBadge: Text(
                      '$minutes',
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: AppSize.font24,
                        color: kJameiaPromoNumber,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    onTap: () {
                      if (!isVip) onToggle(true);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// One promo card. A rounded pastel card with a maroon title + subtitle + orange
/// "›" on the leading edge and [art] on the trailing edge, plus an optional
/// [topEndBadge]. When [active] it lights up in its own [accent] (soft glow +
/// hairline outline) to mark the current store mode; inactive is flat.
class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.background,
    required this.accent,
    required this.active,
    required this.title,
    required this.subtitle,
    required this.art,
    required this.onTap,
    this.topEndBadge,
    this.mirrorArtInRtl = false,
  });

  final Color background;
  final Color accent;
  final bool active;
  final String title;
  final String subtitle;
  final Widget art;
  final Widget? topEndBadge;
  final VoidCallback onTap;

  /// Horizontally flip [art] in RTL so a directional graphic (the scooter)
  /// faces the same way relative to the card in Arabic as in English.
  final bool mirrorArtInRtl;

  @override
  Widget build(BuildContext context) {
    final flip = mirrorArtInRtl && context.locale.languageCode == 'ar';
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSize.r16),
        onTap: onTap,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            // Figma card aspect ≈ 173:123 → width × 0.71, then 15% shorter.
            final h = w * 0.71 * 0.85;
            return Container(
              height: h,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(AppSize.r16),
                // Active mode → 2px accent outline (transparent when inactive so
                // the layout never shifts) + soft accent glow. Inactive → the
                // Figma resting two-drop shadow.
                border: Border.all(
                  color: accent.withValues(alpha: active ? 1 : 0),
                  width: 2,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.primaryText.withValues(alpha: 0.10),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                        BoxShadow(
                          color: AppColors.primaryText.withValues(alpha: 0.10),
                          blurRadius: 2,
                          spreadRadius: -1,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Stack(
                children: [
                  // Trailing art, seated toward the bottom-trailing corner.
                  PositionedDirectional(
                    top: h * 0.05,
                    bottom: 0,
                    end: 0,
                    width: w * 0.42,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(
                        end: 4,
                        bottom: 4,
                      ),
                      child: Transform.flip(flipX: flip, child: art),
                    ),
                  ),
                  if (topEndBadge != null)
                    PositionedDirectional(
                      top: 16,
                      end: 12,
                      child: topEndBadge!,
                    ),
                  // Text + arrow (leading). Title + subtitle live in a
                  // FittedBox(scaleDown) so every line stays fully visible.
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        12,
                        16,
                        w * 0.36,
                        8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, tc) => FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.topStart,
                                child: SizedBox(
                                  width: tc.maxWidth,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          color: kJameiaPromoTitle,
                                          fontSize: AppSize.font16,
                                          fontWeight: FontWeight.w700,
                                          height: 1.05,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        subtitle,
                                        style: const TextStyle(
                                          color: kJameiaPromoSubtitle,
                                          fontSize: AppSize.font10,
                                          fontWeight: FontWeight.w500,
                                          height: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const _CircleArrow(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Solid circular chevron "›" affordance (white glyph over a 24dp orange
/// circle). The rounded chevron auto-mirrors under RTL.
class _CircleArrow extends StatelessWidget {
  const _CircleArrow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: kJameiaPromoArrow,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 12,
        color: AppColors.white,
      ),
    );
  }
}
