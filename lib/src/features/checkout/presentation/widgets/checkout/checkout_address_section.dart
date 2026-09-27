import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/domain/entities/jameia_address_entity.dart';
import '../../../../../core/utils/address_display.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../address/presentation/cubit/address_book_cubit.dart';
import '../../cubit/checkout_cubit.dart';
import 'checkout_destination_row.dart';

/// Delivery destination as one flat row: the chosen saved address (from the
/// app-global address book) with the zone the server resolved, or the
/// prompt to pick one. Tapping opens the address list, which pops the
/// picked address (a guest lands on that list's own sign-in prompt).
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
    // Values only: a notes keystroke writes a new draft but rebuilds
    // nothing here.
    final (addressId, zone, selecting) = context
        .select<CheckoutCubit, (String?, String, bool)>(
          (cubit) => (
            cubit.state.draft.addressId,
            cubit.state.selection?.zoneName ?? '',
            cubit.state.isSelecting,
          ),
        );
    final address = context.select<AddressBookCubit, JameiaAddressEntity?>(
      (cubit) => addressId == null ? null : cubit.state.book.byId(addressId),
    );
    return CheckoutDestinationRow(
      icon: Icons.location_on_outlined,
      title: address == null
          ? 'checkout.address_choose'.tr()
          : zone.isEmpty
          ? address.shortPlace
          : '${address.tagText}${Formatters.middot}$zone',
      selecting: selecting,
      onTap: () => _choose(context),
    );
  }
}
