import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/hero_bottom_bar.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../cubit/address_book_cubit.dart';
import '../../cubit/address_book_state.dart';

/// "New address" pinned under the list (the shared [HeroBottomBar] with the
/// primary pill); hidden while signed out — the body then asks to sign in.
class AddressAddBar extends StatelessWidget {
  const AddressAddBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddressBookCubit, AddressBookState, bool>(
      selector: (state) => state.status == AddressBookStatus.signedOut,
      builder: (context, signedOut) {
        if (signedOut) return const SizedBox.shrink();
        return HeroBottomBar(
          child: AppButton(
            label: 'addr.new_address'.tr(),
            onPressed: () => context.push(Routes.addressEdit),
            height: AppSize.s52,
            trailing: const HeroIcon(
              HeroIcons.plus,
              size: AppSize.s20,
              color: AppColors.brandForeground,
            ),
          ),
        );
      },
    );
  }
}
