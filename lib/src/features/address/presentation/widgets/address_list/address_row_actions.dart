import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/domain/entities/jameia_address_entity.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../cubit/address_book_cubit.dart';
import '../../cubit/address_book_state.dart';
import 'address_delete_dialog.dart';
import 'address_row_action.dart';

/// Edit + delete for one row; a small loader replaces both while that row's
/// DELETE is in flight. Rebuilds only when this row's delete flag flips.
class AddressRowActions extends StatelessWidget {
  const AddressRowActions({super.key, required this.address});

  final JameiaAddressEntity address;

  static const double _loaderSize = AppSize.s18;

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<AddressBookCubit>();
    final confirmed = await showJameiaDialog<bool>(
      context,
      barrierLabel: 'addr.delete_barrier_label'.tr(),
      barrierColor: AppColors.overlayPrimary,
      pageBuilder: (_) => const AddressDeleteDialog(),
    );
    if (confirmed ?? false) await cubit.delete(address.id);
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddressBookCubit, AddressBookState, bool>(
      selector: (state) => state.isDeleting(address.id),
      builder: (context, deleting) {
        if (deleting) {
          return const SizedBox(
            width: AppSize.s64,
            height: AppSize.s32,
            child: AppLoader(size: _loaderSize),
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AddressRowAction(
              icon: JameiaIcons.edit,
              tooltip: 'common.edit'.tr(),
              onPressed: () => context.push(Routes.addressEdit, extra: address),
            ),
            AddressRowAction(
              icon: JameiaIcons.delete,
              tooltip: 'common.delete'.tr(),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        );
      },
    );
  }
}
