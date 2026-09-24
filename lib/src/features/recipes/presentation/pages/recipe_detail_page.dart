import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/recipe_detail_cubit.dart';
import '../widgets/recipe_detail_body.dart';

/// One recipe (`GET /v1/recipes/:slug`): its ingredients are products of the
/// store, so the dish can be put in the cart from here. Recipe text arrives
/// resolved for the request language: a language switch reloads.
class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecipeDetailCubit>(
      create: (_) => sl<RecipeDetailCubit>(param1: slug)..load(),
      child: Builder(
        builder: (context) =>
            BlocListener<LocalizationCubit, LocalizationState>(
              listenWhen: (previous, current) =>
                  previous.locale != current.locale,
              listener: (context, _) =>
                  context.read<RecipeDetailCubit>().load(),
              child: const Scaffold(
                backgroundColor: AppColors.mediumBackground,
                body: RecipeDetailBody(),
              ),
            ),
      ),
    );
  }
}
