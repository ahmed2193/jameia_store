import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../cubit/home_cubit.dart';
import '../widgets/home_body.dart';
import '../widgets/home_cart_bar.dart';

/// Home tab — the jm3eia storefront as the backend composes it
/// (`GET /v1/home` + the launch snapshot `GET /v1/init`).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<HomeCubit>()..load(),
    child: const Scaffold(
      backgroundColor: AppColors.mediumBackground,
      body: HomeBody(),
      // Below the feed, above the shell tab bar.
      bottomNavigationBar: HomeCartBar(),
    ),
  );
}
