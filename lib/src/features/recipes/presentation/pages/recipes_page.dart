import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/recipes_cubit.dart';
import '../widgets/recipes_app_bar.dart';
import '../widgets/recipes_body.dart';

/// The store's recipes (`GET /v1/recipes`). Recipe text arrives resolved for
/// the request language, so a language switch reloads.
class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RecipesCubit>(
      create: (_) => sl<RecipesCubit>()..load(),
      child: Builder(
        builder: (context) =>
            BlocListener<LocalizationCubit, LocalizationState>(
              listenWhen: (previous, current) =>
                  previous.locale != current.locale,
              listener: (context, _) => context.read<RecipesCubit>().load(),
              child: Scaffold(
                backgroundColor: AppColors.mediumBackground,
                appBar: RecipesAppBar(title: 'recipes.title'.tr()),
                body: const RecipesBody(),
              ),
            ),
      ),
    );
  }
}
