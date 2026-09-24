import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../cubit/search_cubit.dart';
import '../widgets/search_body.dart';

/// Search tab of the shell: recent terms, the store's categories and brands,
/// and live product suggestions (`GET /v1/products?search=`). The shell
/// rebuilds its tabs on a language switch, so this page never needs its own
/// reload-on-locale listener.
class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<SearchCubit>(
    create: (_) => sl<SearchCubit>()..loadDiscover(),
    child: const Scaffold(backgroundColor: AppColors.white, body: SearchBody()),
  );
}
