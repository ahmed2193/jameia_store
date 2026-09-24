import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/domain/entities/jameia_address_entity.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/utils/address_display.dart';
import '../../../../address/presentation/cubit/address_book_cubit.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_section_title.dart';

/// Delivery destination: the chosen saved address (from the app-global
/// address book) with the zone the server resolved, or the prompt to pick
/// one. Tapping opens the address list, which pops the picked address.
class CheckoutAddressSection extends StatelessWidget {
  const CheckoutAddressSection({super.key});

  Future<void> _choose(BuildContext context) async {
    final picked = await context.push<JameiaAddressEntity>(Routes.addressList);
    if (picked != null && context.mounted) {
      await context.read<CheckoutCubit>().selectAddress(picked.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final addressId = context.select<CheckoutCubit, String?>(
      (cubit) => cubit.state.draft.addressId,
    );
    final zone = context.select<CheckoutCubit, String>(
      (cubit) => cubit.state.selection?.zoneName ?? '',
    );
    final selecting = context.select<CheckoutCubit, bool>(
      (cubit) => cubit.state.isSelecting,
    );
    final address = context.select<AddressBookCubit, JameiaAddressEntity?>(
      (cubit) => addressId == null ? null : cubit.state.book.byId(addressId),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CheckoutSectionTitle('checkout.address_title'.tr()),
        ListTile(
          contentPadding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.s16,
          ),
          leading: const Icon(
            JameiaIcons.locationOutline,
            size: AppSize.s22,
            color: AppColors.primary,
          ),
          title: Text(
            address == null ? 'checkout.address_choose'.tr() : address.tagText,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primaryText,
            ),
          ),
          subtitle: address == null
              ? null
              : Text(
                  zone.isEmpty
                      ? address.shortPlace
                      : '${address.shortPlace} · $zone',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionLarge.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
          trailing: selecting
              ? const SizedBox(
                  width: AppSize.s20,
                  height: AppSize.s20,
                  child: CircularProgressIndicator(strokeWidth: AppSize.s2),
                )
              : Text(
                  'checkout.address_change'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.link,
                  ),
                ),
          onTap: selecting ? null : () => _choose(context),
        ),
      ],
    );
  }
}
