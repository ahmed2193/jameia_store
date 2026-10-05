import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/search_cubit.dart';
import '../widgets/search_body.dart';

/// Search tab of the shell: recent terms, the store's categories and brands
/// (the device copy first), and live product suggestions
/// (`GET /v1/products?search=`). The categories and brands arrive resolved
/// for the request language, so a language switch reads them again — the
/// device copy in that language first — over the blocks on screen (the
/// shell keeps its tabs across a switch); a returning connection refreshes
/// what could not load.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<SearchCubit>(
    create: (_) => sl<SearchCubit>()..loadDiscover(),
    child: BlocListener<LocalizationCubit, LocalizationState>(
      listenWhen: (previous, current) => previous.locale != current.locale,
      listener: (context, _) => context.read<SearchCubit>().loadDiscover(),
      child: const Scaffold(
        backgroundColor: AppColors.white,
        body: SearchBody(),
      ),
    ),
  );
}
