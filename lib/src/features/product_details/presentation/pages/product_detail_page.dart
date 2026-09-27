import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/route_args/product_detail_args.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/product_detail_cubit.dart';
import '../cubit/product_reviews_cubit.dart';
import '../widgets/pdp_body.dart';
import '../widgets/pdp_bottom_bar.dart';

/// A product of the backend catalogue (`GET /v1/products/:slug`) with its
/// reviews (`GET /v1/products/:slug/reviews`), loaded side by side. Catalogue
/// text is resolved by the backend for the request language, so a language
/// switch reloads both. Hero style: a full-bleed grey gallery under
/// a white sheet of flat blocks; the buy bar's fly-to-cart takes off from
/// the gallery ([_galleryKey]).
class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.args});

  final ProductDetailArgs args;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final GlobalKey _galleryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProductDetailCubit>(
          create: (_) => sl<ProductDetailCubit>(param1: args)..load(),
        ),
        BlocProvider<ProductReviewsCubit>(
          create: (_) => sl<ProductReviewsCubit>(param1: args.slug)..load(),
        ),
      ],
      child: Builder(
        builder: (context) =>
            BlocListener<LocalizationCubit, LocalizationState>(
              listenWhen: (previous, current) =>
                  previous.locale != current.locale,
              listener: (context, _) {
                context.read<ProductDetailCubit>().load();
                context.read<ProductReviewsCubit>().load();
              },
              child: Scaffold(
                backgroundColor: AppColors.white,
                body: PdpBody(galleryKey: _galleryKey),
                bottomNavigationBar: PdpBottomBar(galleryKey: _galleryKey),
              ),
            ),
      ),
    );
  }
}
