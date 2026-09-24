import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/design/jameia_assets.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/skeletons.dart';
// Data-layer mapper imported for the P2.9 boundary reverse-map (entity ->
// core ServiceRegionItem) at the confirm-pop call site.
import '../../data/mappers/service_region_mapper.dart';
import '../cubit/choose_location_cubit.dart';

/// Jameia `choose_location_page` (C-PAGE v0.0.42) clone — the serviceable
/// COUNTRY/REGION picker (region gating / first launch).
///
/// CRITICAL ARCHETYPE (RE §4): the real page is a plain WHITE single-select
/// country/region list — NO map, NO pin, NO search. The only assets are
/// `check / checked / page_back`. The map-with-pin flow belongs to the address
/// create page (`c_address_select_page`), not here.
///
/// Section order (RE §4.3):
///   1. Nav bar — back (`page_back`) + title "Choose your location" (20dp/700).
///   2. Grey subtitle "Please select your city or region" (12dp `#808080`).
///   3. Flat single-select region cells (min-h 58dp, name 16dp `#222222`→bold,
///      trailing 16dp check/checked PNG, divider 0.5dp `#00000012`).
///   4. Sticky Confirm CTA (h50dp radius25, disabled `#cacaca`/enabled `#ffe41f`).
///
/// Flow (RE §4.2): default selection = persisted active region (NOT first). Tap
/// cell → single-select; on Confirm, if the picked region differs from the
/// active region, a region-switch confirm sheet ("Switch country/region") gates
/// the commit before `switchRegion(...)` + pop.
class ChooseLocationPage extends StatelessWidget {
  const ChooseLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ChooseLocationCubit>(),
      child: const _ChooseLocationView(),
    );
  }
}

class _ChooseLocationView extends StatelessWidget {
  const _ChooseLocationView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Real page is a plain WHITE list (RE §4.3), not the grey app bg.
      backgroundColor: AppColors.white,
      appBar: const _ChooseLocationAppBar(),
      body: BlocBuilder<ChooseLocationCubit, ChooseLocationState>(
        builder: (context, state) {
          return switch (state.status) {
            ChooseLocationStatus.initial ||
            ChooseLocationStatus.loading => const Padding(
              padding: EdgeInsets.all(AppSpacing.s16),
              child: Skeletonized(loading: true, child: ListSkeleton(count: 6)),
            ),
            ChooseLocationStatus.error => const _ErrorView(),
            ChooseLocationStatus.loaded ||
            ChooseLocationStatus.empty => const _Loaded(),
          };
        },
      ),
      bottomNavigationBar: const _ConfirmBar(),
    );
  }
}

// ── 1. Nav bar ────────────────────────────────────────────────────────────────

class _ChooseLocationAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ChooseLocationAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 0,
      leading: PressScale(
        onTap: () => Navigator.maybePop(context),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.s12),
          // RE §4.3 back glyph = `page_back`.
          child: Icon(JameiaIcons.back, size: 22, color: AppColors.primaryText),
        ),
      ),
      // i18n address_addresspage_ChooseRegion — title 20dp/700 (RE §4.3).
      title: Text(
        'region.title'.tr(),
        style: AppTextStyles.headingLarge.copyWith(
          fontSize: AppSize.font20,
          fontWeight: AppTextStyles.bold,
          color: AppColors.primaryText,
        ),
      ),
    );
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded();

  @override
  Widget build(BuildContext context) {
    return ContentClamp(
      child: CustomScrollView(
        slivers: const [
          // 2. Grey subtitle under the nav bar.
          SliverToBoxAdapter(child: _PickerSubtitle()),
          // 3. Flat single-select region cells.
          _RegionSliverList(),
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.s16)),
        ],
      ),
    );
  }
}

// ── 2. Grey subtitle ──────────────────────────────────────────────────────────

class _PickerSubtitle extends StatelessWidget {
  const _PickerSubtitle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      // 16dp side pad; tightened above the first cell.
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.s16,
        AppSpacing.s4,
        AppSpacing.s16,
        AppSpacing.s12,
      ),
      // i18n address_addresspage_ChooseRegion1 — 12dp `#808080` (RE §4.3).
      child: Text(
        'region.subtitle'.tr(),
        style: AppTextStyles.captionLarge.copyWith(
          color: AppColors.secondaryText, // #808080
        ),
      ),
    );
  }
}

// ── 3. Single-select region list ──────────────────────────────────────────────

class _RegionSliverList extends StatelessWidget {
  const _RegionSliverList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChooseLocationCubit, ChooseLocationState>(
      buildWhen: (a, b) => a != b,
      builder: (context, state) {
        if (state.status != ChooseLocationStatus.loaded &&
            state.status != ChooseLocationStatus.empty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        final regions = state.regions;
        if (regions.isEmpty) {
          // i18n empty — "We are working to expand our service…" (RE §4.3).
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.s24,
                vertical: AppSpacing.s40,
              ),
              child: _EmptyRegions(),
            ),
          );
        }
        final cubit = context.read<ChooseLocationCubit>();
        return SliverList.builder(
          itemCount: regions.length,
          itemBuilder: (_, i) {
            final r = regions[i];
            return StaggerEntrance(
              index: i,
              child: _RegionTile(
                region: r,
                selected: r.region == state.selectedId,
                // Last cell drops the divider.
                showDivider: i != regions.length - 1,
                onTap: () => cubit.select(r.region),
              ),
            );
          },
        );
      },
    );
  }
}

/// Flat region cell — NO avatar / card border (RE §4.3). Min-height 58dp, name
/// 16dp `#222222` (bold on select), trailing 16dp check, 0.5dp `#00000012`
/// divider.
class _RegionTile extends StatelessWidget {
  const _RegionTile({
    required this.region,
    required this.selected,
    required this.showDivider,
    required this.onTap,
  });

  final ServiceRegionItemEntity region;
  final bool selected;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Disabled (gated-off) regions read greyed and are not tappable.
    final enabled = region.enabled;
    final nameColor = enabled
        ? AppColors
              .primaryText // #222222
        : AppColors.tertiaryText;

    // Passive PressScale (no onTap) so the InkWell keeps its ripple.
    return PressScale(
      enabled: enabled,
      child: Material(
        color: AppColors.white,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 58), // RE §4.3
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s16,
              vertical: AppSpacing.s12,
            ),
            decoration: BoxDecoration(
              border: showDivider
                  ? const Border(
                      bottom: BorderSide(
                        // 0.5dp `#00000012` (RE §2.2 / §4.3).
                        color: AppColors.hairlineInk07,
                        width: 0.5,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        region.regionName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headingMedium.copyWith(
                          fontSize: AppSize.font16,
                          color: nameColor,
                          // Bold on select (RE §4.3).
                          fontWeight: selected
                              ? AppTextStyles.bold
                              : AppTextStyles.regular,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      Text(
                        region.cityName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.captionLarge.copyWith(
                          color: AppColors.tertiaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                _CheckMark(selected: selected),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Trailing single-select check — real Jameia 16x16 `check` (empty) /
/// `checked` (filled) PNG glyphs shipped in the bundle.
class _CheckMark extends StatelessWidget {
  const _CheckMark({required this.selected});
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return PopScale(
      popKey: selected,
      child: Image.asset(
        selected ? JameiaAssets.checkedIcon : JameiaAssets.checkIcon,
        width: 16,
        height: 16,
      ),
    );
  }
}

class _EmptyRegions extends StatelessWidget {
  const _EmptyRegions();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          JameiaIcons.location,
          size: 40,
          color: AppColors.tertiaryText,
        ),
        const SizedBox(height: AppSpacing.s12),
        Text(
          'region.none'.tr(),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }
}

// ── Error view (Refresh) ──────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              JameiaIcons.location,
              size: 40,
              color: AppColors.tertiaryText,
            ),
            const SizedBox(height: AppSpacing.s12),
            // i18n address_error_content.
            Text(
              'region.error'.tr(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            // i18n Jameia_C_Refresh_XPZP.
            AppOutlineButton(
              label: 'common.refresh'.tr(),
              onPressed: () =>
                  context.read<ChooseLocationCubit>().handleRefreshData(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 4. Sticky confirm CTA ─────────────────────────────────────────────────────

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChooseLocationCubit, ChooseLocationState>(
      buildWhen: (a, b) => a.canConfirm != b.canConfirm,
      builder: (context, state) {
        final canConfirm = state.canConfirm;
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.white,
            border: Border(
              // Top divider 0.5dp `#0000001E` (RE §4.3).
              top: BorderSide(color: AppColors.hairlineInk12, width: 0.5),
            ),
          ),
          child: SafeArea(
            minimum: const EdgeInsets.all(AppSpacing.s16),
            child: AppButton(
              // i18n address_addresspage_confirm.
              label: 'common.confirm'.tr(),
              height: 50, // RE §4.3
              radius: 25, // RE §4.3 pill
              // Enabled `#ffe41f` (AppColors.primary) / disabled `#cacaca`.
              color: AppColors.primary,
              foreground:
                  AppColors.brandForeground, // label white bold 16dp (RE §4.3)
              enabled: canConfirm,
              onPressed: canConfirm ? () => _onConfirm(context) : null,
            ),
          ),
        );
      },
    );
  }

  /// Commit selection. Same region → commit directly. Different region →
  /// region-switch confirm sheet first (RE §4.2).
  Future<void> _onConfirm(BuildContext context) async {
    final cubit = context.read<ChooseLocationCubit>();
    final picked = cubit.selected;
    if (picked == null) return;

    if (cubit.isSwitch(picked.region)) {
      final confirmed = await showJameiaBottomSheet<bool>(
        context,
        backgroundColor: AppColors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(
              AppSize.r12,
            ), // RE §2.2 select-popup radius-top 12dp
          ),
        ),
        builder: (_) => _RegionSwitchSheet(target: picked),
      );
      if (confirmed != true) return;
    }

    await cubit.switchRegion(picked.region);
    // TODO(P2.9-boundary): pop the CORE ServiceRegionItem so callers (home
    // region bar) consume the shared type unchanged.
    if (context.mounted) context.pop(picked.toModel());
  }
}

/// Region-switch confirm sheet (RE §4.2): title "Switch country/region", body
/// "Sure to switch to {newregion}?", Confirm / Maybe later, terms+privacy line.
class _RegionSwitchSheet extends StatelessWidget {
  const _RegionSwitchSheet({required this.target});

  final ServiceRegionItemEntity target;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16,
          AppSpacing.s24,
          AppSpacing.s16,
          AppSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // i18n homepage_address_SwitchCountry_tittle.
            Text(
              'region.switch_title'.tr(),
              style: AppTextStyles.headingLarge.copyWith(
                fontWeight: AppTextStyles.bold,
                color: AppColors.primaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            // i18n address_changeRegion_changecontent ({newregion} filled).
            Text(
              'region.switch_confirm'.tr(args: [target.regionName]),
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            // i18n address_changeRegion_termsandprivacy — link colour `#1F7CFF`.
            Text(
              'region.terms_privacy'.tr(),
              style: AppTextStyles.captionLarge.copyWith(
                color: AppColors.termsLink, // RE §4.2 terms+privacy
              ),
            ),
            const SizedBox(height: AppSpacing.s24),
            AppButton(
              // i18n address_addresspage_confirm.
              label: 'common.confirm'.tr(),
              height: 50,
              radius: 25,
              foreground: AppColors.white,
              onPressed: () => Navigator.pop(context, true),
            ),
            const SizedBox(height: AppSpacing.s8),
            // i18n homepage_address_SwitchCountry_Maybelater.
            AppOutlineButton(
              label: 'region.maybe_later'.tr(),
              height: 50,
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        ),
      ),
    );
  }
}
