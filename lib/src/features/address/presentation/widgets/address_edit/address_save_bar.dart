import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/hero_bottom_bar.dart';
import '../../cubit/address_edit_cubit.dart';

/// The pinned Save bar of the address form, riding on the keyboard. Always
/// tappable, so an invalid form shows its inline errors; while the POST /
/// PATCH is in flight the page's busy overlay holds the screen and the pill
/// keeps its label under it. The keyboard leaves with the tap: the overlay
/// covers a still screen (no caret handle over its disc) and an invalid
/// form shows all of its errors.
class AddressSaveBar extends StatelessWidget {
  const AddressSaveBar({super.key});

  @override
  Widget build(BuildContext context) {
    return HeroBottomBar(
      child: AppButton(
        label: 'addr.save_address'.tr(),
        onPressed: () {
          FocusManager.instance.primaryFocus?.unfocus();
          unawaited(context.read<AddressEditCubit>().save());
        },
      ),
    );
  }
}
