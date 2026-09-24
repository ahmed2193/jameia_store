import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/brands_cubit.dart';
import '../widgets/brands/brands_body.dart';
import '../widgets/listing/catalog_app_bar.dart';
import '../widgets/listing/catalog_cart_bar.dart';

/// The store's brands (`GET /v1/brands`); a brand opens its product listing.
class BrandsPage extends StatelessWidget {
  const BrandsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BrandsCubit>(
      create: (_) => sl<BrandsCubit>()..load(),
      child: Builder(
        builder: (context) =>
            BlocListener<LocalizationCubit, LocalizationState>(
              listenWhen: (previous, current) =>
                  previous.locale != current.locale,
              listener: (context, _) => context.read<BrandsCubit>().load(),
              child: Scaffold(
                backgroundColor: AppColors.mediumBackground,
                appBar: CatalogAppBar(title: 'shop.brands'.tr()),
                body: const BrandsBody(),
                bottomNavigationBar: const CatalogCartBar(),
              ),
            ),
      ),
    );
  }
}
