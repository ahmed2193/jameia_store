import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/fade_through_switcher.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/delivery_code_cubit.dart';
import 'delivery_code_content.dart';

/// The delivery-code screen: the loader while the saved code is read, its
/// error + retry when it cannot be, then the cards ([DeliveryCodeContent]) —
/// fading through from one to the next. Edits and saves never rebuild it.
class DeliveryCodeBody extends StatelessWidget {
  const DeliveryCodeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeliveryCodeCubit, DeliveryCodeState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) => FadeThroughSwitcher(
        // initial and loading are one loader.
        stateKey: state.status == DeliveryCodeStatus.initial
            ? DeliveryCodeStatus.loading
            : state.status,
        child: switch (state.status) {
          DeliveryCodeStatus.initial ||
          DeliveryCodeStatus.loading => const AppLoader(),
          DeliveryCodeStatus.error => FailureView(
            failure: state.failure,
            onRetry: context.read<DeliveryCodeCubit>().load,
          ),
          DeliveryCodeStatus.loaded => const DeliveryCodeContent(),
        },
      ),
    );
  }
}
