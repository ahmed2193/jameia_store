import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/widgets/hero_map_button.dart';
import '../../cubit/address_picker_cubit.dart';
import '../../cubit/address_picker_state.dart';

/// "Show my location" (the Glovo arrow): the map glides to the device's
/// position; the Hero dots spin in the button while it is being found.
class AddressLocateButton extends StatelessWidget {
  const AddressLocateButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddressPickerCubit, AddressPickerState, bool>(
      selector: (state) => state.locating,
      builder: (context, locating) => HeroMapButton(
        icon: HeroIcons.navigation,
        tooltip: 'addr.map.locate_me'.tr(),
        busy: locating,
        onPressed: context.read<AddressPickerCubit>().locate,
      ),
    );
  }
}
