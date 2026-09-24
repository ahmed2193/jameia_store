import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/route_args/product_listing_args.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/product_listing_cubit.dart';
import '../widgets/listing/catalog_app_bar.dart';
import '../widgets/listing/catalog_cart_bar.dart';
import '../widgets/listing/product_listing_body.dart';

/// Any product list of the backend (`GET /v1/products`): a brand, a
/// collection ("view all" of a home rail), a tag, the offers. A language
/// switch reloads it (product names arrive resolved for the request language).
class ProductListingPage extends StatelessWidget {
  const ProductListingPage({super.key, required this.args});

  final ProductListingArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductListingCubit>(
      create: (_) => sl<ProductListingCubit>(param1: args.query)..load(),
      child: Builder(
        builder: (context) =>
            BlocListener<LocalizationCubit, LocalizationState>(
              listenWhen: (previous, current) =>
                  previous.locale != current.locale,
              listener: (context, _) =>
                  context.read<ProductListingCubit>().load(),
              child: Scaffold(
                backgroundColor: AppColors.mediumBackground,
                appBar: CatalogAppBar(title: args.title),
                body: const ProductListingBody(),
                bottomNavigationBar: const CatalogCartBar(),
              ),
            ),
      ),
    );
  }
}
