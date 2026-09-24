import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/navigation/jameia_snack_bar.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/product_detail_cubit.dart';
import '../cubit/product_detail_state.dart';
import 'pdp_header_block.dart';
import 'pdp_loaded_view.dart';
import 'pdp_scaffold_view.dart';

/// Switches the product page on the cubit state. While the detail loads it
/// paints the card the customer tapped (photo, name) instead of a bare
/// spinner; an unknown slug is a "not found" empty state; any other failure is
/// the error view with retry (offline = the error view with "no internet").
/// A failed reload keeps the page and shows a snack bar.
class PdpBody extends StatelessWidget {
  const PdpBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductDetailCubit, ProductDetailState>(
      listenWhen: (previous, current) =>
          current.failure != null &&
          current.isLoaded &&
          previous.failure != current.failure,
      listener: (context, state) =>
          showJameiaSnackBar(context, state.failure!.localizedMessage),
      // Quantity and the gallery page have their own builders: never rebuild
      // the whole page for them.
      buildWhen: (previous, current) =>
          previous.status != current.status ||
          previous.detail != current.detail ||
          previous.selectedVariantId != current.selectedVariantId,
      builder: (context, state) {
        final detail = state.detail;
        if (detail != null) {
          return PdpLoadedView(
            detail: detail,
            selectedVariantId: state.selectedVariantId,
          );
        }
        if (state.isNotFound) {
          return SafeArea(
            child: EmptyStateView(
              message: 'product.not_found'.tr(),
              icon: Icons.search_off_rounded,
              actionLabel: 'common.back'.tr(),
              onAction: () => context.pop(),
            ),
          );
        }
        if (state.status == ProductDetailStatus.error) {
          return SafeArea(
            child: ErrorView(
              message: state.failure?.localizedMessage,
              onRetry: context.read<ProductDetailCubit>().load,
            ),
          );
        }
        final preview = state.preview;
        if (preview == null) return const SafeArea(child: AppLoader());
        return PdpScaffoldView(
          images: [if (preview.image.isNotEmpty) preview.image],
          sections: [
            PdpHeaderBlock(product: preview, inStock: preview.inStock),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.s24),
              child: AppLoader(),
            ),
          ],
        );
      },
    );
  }
}
