import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/routing/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/address_list_cubit.dart';

/// KeeTa `address_select_page` (C-PAGE v0.0.136) clone — the saved-address list.
///
/// Doubles as a **picker**: tapping a card pops the route with the chosen
/// [KeetaAddress] so a caller (checkout / home address bar) can reuse it. "Add
/// new address" routes to [Routes.addressEdit]; the edit pencil routes there too
/// with the address as an argument.
class AddressListScreen extends StatelessWidget {
  const AddressListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddressListCubit(sl<KeetaRepository>())..load(),
      child: const _AddressListView(),
    );
  }
}

class _AddressListView extends StatelessWidget {
  const _AddressListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(KeetaIcons.back, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'My addresses',
          style: AppTextStyles.headingLarge
              .copyWith(fontWeight: AppTextStyles.bold),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ContentClamp(
          child: BlocBuilder<AddressListCubit, AddressListState>(
            builder: (context, state) {
              return switch (state) {
                AddressListLoading() => const AppLoader(),
                AddressListError() => ErrorView(
                    onRetry: () => context.read<AddressListCubit>().load()),
                AddressListLoaded(:final addresses) =>
                  _loaded(context, addresses),
              };
            },
          ),
        ),
      ),
      bottomNavigationBar: const _AddAddressBar(),
    );
  }

  Widget _loaded(BuildContext context, List<KeetaAddress> addresses) {
    if (addresses.isEmpty) {
      return const EmptyStateView(
        message: 'No saved addresses yet',
        icon: KeetaIcons.address,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s12,
      ),
      itemCount: addresses.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.s12),
      itemBuilder: (_, i) {
        final a = addresses[i];
        return _AddressCard(
          address: a,
          onTap: () => Navigator.pop(context, a),
          onEdit: () => Navigator.pushNamed(
            context,
            Routes.addressEdit,
            arguments: a,
          ),
        );
      },
    );
  }
}

/// One saved-address card: label chip + default badge, full address line,
/// recipient + phone meta row, and an edit pencil. Whole card is tappable for
/// the picker reuse.
class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onTap,
    required this.onEdit,
  });

  final KeetaAddress address;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsetsDirectional.only(top: AppSpacing.s2),
                child: Icon(KeetaIcons.location,
                    size: 20, color: AppColors.primaryText),
              ),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _LabelChip(label: address.label),
                        if (address.isDefault) ...[
                          const SizedBox(width: AppSpacing.s6),
                          const _DefaultBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s6),
                    Text(
                      address.fullText,
                      style: AppTextStyles.headingSmall
                          .copyWith(fontWeight: AppTextStyles.bold),
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Text(
                      '${address.recipient}  ·  ${address.phone}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionLarge
                          .copyWith(color: AppColors.tertiaryText),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(KeetaIcons.edit,
                    size: 18, color: AppColors.secondaryText),
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Home / Office / Other label chip.
class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s8, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        color: AppColors.smallBackground,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        label,
        style: AppTextStyles.captionMedium
            .copyWith(color: AppColors.secondaryText),
      ),
    );
  }
}

/// "Default" badge — brand-tinted pill shown on the default address.
class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s8, vertical: AppSpacing.s2),
      decoration: BoxDecoration(
        color: AppColors.brandLightBg,
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Text(
        'Default',
        style: AppTextStyles.captionMedium.copyWith(
          color: AppColors.accent4Foreground,
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}

/// Sticky bottom "Add new address" CTA.
class _AddAddressBar extends StatelessWidget {
  const _AddAddressBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(AppSpacing.s12),
      child: AppButton(
        label: 'Add new address',
        onPressed: () => Navigator.pushNamed(context, Routes.addressEdit),
        trailing: const Icon(Icons.add,
            size: 20, color: AppColors.brandForeground),
      ),
    );
  }
}
