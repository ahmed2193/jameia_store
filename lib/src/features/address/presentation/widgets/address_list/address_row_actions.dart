import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/domain/entities/hero_address_entity.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../cubit/address_book_cubit.dart';
import 'address_row_action.dart';

/// Edit + delete for one row. A confirmed delete takes the row out at once;
/// the DELETE waits while the page's "Address deleted · Undo" snack is up
/// (B1-17): the page releases it when the snack closes without the Undo.
class AddressRowActions extends StatelessWidget {
  const AddressRowActions({super.key, required this.address});

  final HeroAddressEntity address;

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<AddressBookCubit>();
    final confirmed = await showHeroConfirmDialog(
      context,
      title: 'addr.delete_confirm_title'.tr(),
      message: 'addr.delete_confirm_body'.tr(),
      icon: HeroIcons.trash,
      confirmLabel: 'common.delete'.tr(),
      destructive: true,
    );
    if (confirmed) {
      await cubit.delete(address.id, holdForUndo: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AddressRowAction(
          icon: HeroIcons.edit,
          tooltip: 'common.edit'.tr(),
          onPressed: () => context.push(Routes.addressEdit, extra: address),
        ),
        AddressRowAction(
          icon: HeroIcons.trash,
          tooltip: 'common.delete'.tr(),
          onPressed: () => _confirmDelete(context),
        ),
      ],
    );
  }
}
