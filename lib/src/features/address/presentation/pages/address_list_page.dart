import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/jameia_assets.dart';
import '../../../../core/design/jameia_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/utils/jameia_geocode.dart' show LabelType;
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../../../../core/widgets/skeletons.dart';
// Data-layer mapper imported for the P2.9 boundary reverse-map (entity ->
// core JameiaAddress) at the picker-pop / edit-deep-link call sites.
import '../../data/mappers/address_mapper.dart';
import '../../domain/entities/jameia_address_entity.dart';
import '../cubit/address_list_cubit.dart';

/// Jameia `mine_address` (bundle v0.0.38) clone — the saved-address management
/// list. Read / edit / delete / add; never embeds the map (deep-links to the
/// create page `Routes.addressEdit`). Reached from Mine → "My addresses".
///
/// Doubles as a **picker**: tapping a row pops the route with the chosen
/// [JameiaAddress] so a caller (checkout / home address bar) can reuse it.
///
/// RE master doc §5: white grouped card (12dp side pad, first/last radius 12dp,
/// row v-pad 20dp, divider 0.5dp #22222214), page bg #F5F6FA, per-row 32dp
/// delete glyph → confirm dialog, bottom "New address" CTA (#FFE41F r16 h50).
/// Per §5 there is NO "Default" pill in real Jameia — default is surfaced by
/// ordering only (the cubit hoists the default to the top).
class AddressListPage extends StatelessWidget {
  const AddressListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AddressListCubit>(),
      child: const _AddressListView(),
    );
  }
}

class _AddressListView extends StatelessWidget {
  const _AddressListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground, // page bg #F5F6FA (RE §5)
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(JameiaIcons.back, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        // i18n personal_page_myaddress
        title: Text(
          'addr.my_addresses'.tr(),
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ContentClamp(
          child: BlocBuilder<AddressListCubit, AddressListState>(
            builder: (context, state) {
              return switch (state.status) {
                AddressListStatus.initial ||
                AddressListStatus.loading => const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s12,
                  ),
                  child: Skeletonized(
                    loading: true,
                    child: ListSkeleton(count: 4),
                  ),
                ),
                AddressListStatus.error => ErrorView(
                  // i18n address_error_content / Jameia_C_Refresh_XPZP
                  onRetry: () => context.read<AddressListCubit>().load(),
                ),
                AddressListStatus.loaded ||
                AddressListStatus.empty => _loaded(context, state.addresses),
              };
            },
          ),
        ),
      ),
      bottomNavigationBar: const _AddAddressBar(),
    );
  }

  Widget _loaded(BuildContext context, List<JameiaAddressEntity> addresses) {
    if (addresses.isEmpty) {
      // i18n address_addressmanagement_blankpagetext_final
      return EmptyStateView(
        message: 'addr.no_saved_addresses'.tr(),
        icon: JameiaIcons.address,
      );
    }
    // RE §5: a single white grouped CARD (not separate per-row cards). 12dp side
    // pad, first/last corners radius 12dp, hairline dividers between rows.
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s12,
      ),
      children: [
        RepaintBoundary(
          child: Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.card), // 12dp
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < addresses.length; i++) ...[
                  if (i > 0) const _RowDivider(),
                  StaggerEntrance(
                    index: i,
                    child: _AddressRow(
                      address: addresses[i],
                      // TODO(P2.9-boundary): picker pops the CORE JameiaAddress so
                      // checkout / home consume the shared row unchanged.
                      onTap: () => context.pop(addresses[i].toModel()),
                      // TODO(P2.9-boundary): routing builds AddressEditPage with
                      // a CORE JameiaAddress arg, so reverse-map before pushing.
                      onEdit: () =>
                          _openEditor(context, addresses[i].toModel()),
                      onDelete: () => _confirmDelete(context, addresses[i]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Opens the address editor (`Routes.addressEdit`) and, when it pops with a
  /// saved [JameiaAddress] (new or edited), persists it via the cubit so it
  /// shows immediately and survives an app restart. Pass [edit] for edit mode,
  /// or null to create a new address.
  Future<void> _openEditor(BuildContext context, [JameiaAddress? edit]) async {
    final saved = await context.push<Object?>(Routes.addressEdit, extra: edit);
    if (saved is JameiaAddress && context.mounted) {
      context.read<AddressListCubit>().upsert(saved);
    }
  }

  /// Delete confirm — RE §5 centered dialog (mirrors the settings log-out
  /// dialog: 24dp side margin, 8dp radius, scale-in via [showJameiaDialog]).
  /// i18n address_addressmanagementpage_deleteconfirmtoast + Cancel / Confirm.
  Future<void> _confirmDelete(
    BuildContext context,
    JameiaAddressEntity a,
  ) async {
    final cubit = context.read<AddressListCubit>();
    final confirmed = await showJameiaDialog<bool>(
      context,
      barrierLabel: 'addr.delete_barrier_label'.tr(),
      barrierColor: AppColors.overlayPrimary,
      pageBuilder: (_) => const _DeleteConfirmDialog(),
    );
    if (confirmed == true) cubit.delete(a.id);
  }
}

/// Hairline row divider: 0.5dp #22222214 (RE §5). Indented to clear the label
/// glyph column so it reads as a list separator, not a full card cut.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 0.5,
      thickness: 0.5,
      indent: AppSpacing.s12,
      endIndent: AppSpacing.s12,
      color: AppColors.rowDividerInk, // #22222214
    );
  }
}

/// One saved-address row inside the grouped card: label chip (driven by the
/// `labelType` ENUM, 18dp glyph + 6dp gap per RE §5), full address line,
/// recipient + phone meta, plus edit + delete actions. The whole row is
/// tappable for the picker reuse.
class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.address,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final JameiaAddressEntity address;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Recipient · phone meta line, with graceful fallbacks for empty fields so a
  /// dangling separator never shows.
  String get _metaLine {
    final name = address.recipient.trim();
    final phone = address.phone.trim();
    final parts = [if (name.isNotEmpty) name, if (phone.isNotEmpty) phone];
    return parts.isEmpty ? 'addr.no_contact'.tr() : parts.join('  ·  ');
  }

  @override
  Widget build(BuildContext context) {
    // Resolve the Jameia tag enum from the entity's raw code (the entity is
    // framework-free and cannot carry the LabelType type itself).
    final labelType = LabelType.fromCode(address.labelTypeCode);
    // Passive PressScale (no onTap) so the InkWell keeps its ripple while the
    // whole row gives the subtle press feel.
    return PressScale(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          // RE §5: row v-pad 20dp, 12dp side pad.
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s20,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(top: AppSpacing.s2),
                child: _LabelGlyph(labelType: labelType),
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _labelText(labelType),
                      style: AppTextStyles.captionMedium.copyWith(
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      address.fullText,
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: AppTextStyles.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      _metaLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionLarge.copyWith(
                        color: AppColors.labelGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              // Edit pencil.
              _RowAction(
                icon: JameiaIcons.edit,
                color: AppColors.secondaryText,
                onPressed: onEdit,
              ),
              // Delete glyph (RE §5: 32dp tap target).
              _RowAction(
                icon: JameiaIcons.delete,
                color: AppColors.secondaryText,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact 32dp icon button used for the edit / delete row actions.
class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
      ),
    );
  }
}

/// Per-`labelType` glyph: the 18dp global label icon (RE §5 / §2.1).
class _LabelGlyph extends StatelessWidget {
  const _LabelGlyph({required this.labelType});
  final LabelType labelType;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetFor(labelType),
      width: 18,
      height: 18,
      fit: BoxFit.contain,
    );
  }
}

/// Maps `labelType` → its shipped 18dp global glyph (RE §2.1). FaceDelivery /
/// AssignedPlace fall back to the generic "other" glyph.
String _assetFor(LabelType t) => switch (t) {
  LabelType.home => JameiaAssets.labelHome,
  LabelType.work => JameiaAssets.labelOffice,
  LabelType.hangout => JameiaAssets.labelGathering,
  LabelType.faceDelivery ||
  LabelType.assignedPlace ||
  LabelType.other => JameiaAssets.labelOther,
};

/// Tag display text per `labelType` (i18n address_label_*).
String _labelText(LabelType t) => switch (t) {
  LabelType.home => 'addr.tag.home'.tr(),
  LabelType.work => 'addr.tag.work'.tr(),
  LabelType.hangout => 'addr.tag.gathering'.tr(),
  LabelType.faceDelivery ||
  LabelType.assignedPlace ||
  LabelType.other => 'addr.tag.other'.tr(),
};

/// Sticky bottom "New address" CTA — RE §5: #FFE41F, radius 16dp, h50dp.
class _AddAddressBar extends StatelessWidget {
  const _AddAddressBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(AppSpacing.s12),
      child: AppButton(
        // i18n address_addressmanagementpage_addaddress
        label: 'addr.new_address'.tr(),
        onPressed: () => _addNew(context),
        height: 50,
        radius: AppRadius.r3, // 16dp
        trailing: const Icon(
          Icons.add,
          size: 20,
          color: AppColors.brandForeground,
        ),
      ),
    );
  }

  /// Opens the editor for a NEW address and persists the result via the cubit
  /// so it appears immediately and survives an app restart. Guarded by
  /// [BuildContext.mounted] across the async gap.
  Future<void> _addNew(BuildContext context) async {
    final saved = await context.push<Object?>(Routes.addressEdit);
    if (saved is JameiaAddress && context.mounted) {
      context.read<AddressListCubit>().upsert(saved);
    }
  }
}

/// Centered delete-confirm dialog (RE §5). Mirrors the settings log-out dialog:
/// 24dp side margin, 8dp radius, Cancel / Confirm. Presented through
/// [showJameiaDialog] for the scale-in + fade entrance.
class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s24),
        child: Material(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppSize.r8),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.s16,
              AppSpacing.s24,
              AppSpacing.s16,
              AppSpacing.s12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // i18n address_addressmanagementpage_deleteconfirmtoast
                Text(
                  'addr.delete_confirm_body'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                // i18n address_addressmanagementpage_deleteconfirm_button2
                AppButton(
                  label: 'common.confirm'.tr(),
                  color: AppColors.primary,
                  foreground: AppColors.primaryText,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: AppSpacing.s8),
                // i18n address_addressmanagementpage_deleteconfirm_button1
                AppOutlineButton(
                  label: 'common.cancel'.tr(),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
