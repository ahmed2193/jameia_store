import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../cart/presentation/cubit/cart_state.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/home_cubit.dart';
import '../widgets/home_body.dart';
import '../widgets/home_cart_bar.dart';
import '../widgets/home_first_order_bar.dart';

/// Home tab — the Hero storefront as the backend composes it
/// (`GET /v1/home` + the launch snapshot `GET /v1/init`). Both arrive
/// resolved for the request language, so a language switch reads them again
/// — the device copy in that language first — with the feed kept on screen
/// meanwhile (the shell keeps its tabs across a switch). An order placed
/// from the cart spends the first-order gift (its bar goes).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    // Already reading: the read the splash started (B1-14), else a fresh
    // one.
    create: (_) => sl<HomeCubit>(),
    child: MultiBlocListener(
      listeners: [
        BlocListener<LocalizationCubit, LocalizationState>(
          listenWhen: (previous, current) => previous.locale != current.locale,
          listener: (context, _) => context.read<HomeCubit>().load(),
        ),
        BlocListener<CartCubit, CartState>(
          listenWhen: (previous, current) =>
              previous.ordersPlaced != current.ordersPlaced,
          listener: (context, _) => context.read<HomeCubit>().onOrderPlaced(),
        ),
      ],
      child: const Scaffold(
        backgroundColor: AppColors.white,
        body: HomeBody(),
        // Below the feed, on the shell tab bar: the minimum-order bar, or
        // the first-order free-delivery bar while the customer is due it.
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [HomeCartBar(), HomeFirstOrderBar()],
        ),
      ),
    ),
  );
}
