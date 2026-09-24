import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../cubit/address_book_cubit.dart';
import '../../cubit/address_book_state.dart';

/// Sticky "New address" CTA (RE §5: brand yellow, r16, 50dp). Hidden behind
/// the sign-in prompt, since a guest cannot save an address.
class AddressAddBar extends StatelessWidget {
  const AddressAddBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddressBookCubit, AddressBookState, bool>(
      selector: (state) => state.status == AddressBookStatus.signedOut,
      builder: (context, signedOut) {
        if (signedOut) return const SizedBox.shrink();
        return SafeArea(
          minimum: const EdgeInsets.all(AppSpacing.s12),
          child: AppButton(
            label: 'addr.new_address'.tr(),
            onPressed: () => context.push(Routes.addressEdit),
            height: AppSize.s50,
            radius: AppRadius.r3,
            trailing: const Icon(
              Icons.add,
              size: AppSize.s20,
              color: AppColors.brandForeground,
            ),
          ),
        );
      },
    );
  }
}
