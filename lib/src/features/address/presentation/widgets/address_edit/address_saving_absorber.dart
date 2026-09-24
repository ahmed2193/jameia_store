import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_edit_state.dart';

/// Ignores taps and typing on [child] while the address is being saved, so
/// nothing changes (or navigates back to the map) under an in-flight request.
class AddressSavingAbsorber extends StatelessWidget {
  const AddressSavingAbsorber({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddressEditCubit, AddressEditState, bool>(
      selector: (state) => state.isSaving,
      builder: (context, saving) =>
          AbsorbPointer(absorbing: saving, child: child),
    );
  }
}
