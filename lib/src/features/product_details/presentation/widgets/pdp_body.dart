import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/navigation/screen_failure_listener.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/product_detail_cubit.dart';
import '../cubit/product_detail_state.dart';
import '../cubit/product_reviews_cubit.dart';
import 'pdp_load_failure.dart';
import 'pdp_loaded_view.dart';
import 'pdp_preview_view.dart';

/// Switches the product page on the cubit state. While the detail loads it
/// paints the card the customer tapped (photo, name) instead of a bare
/// spinner — and keeps it when the detail cannot load, with the reason and
/// "Try again" under it (offline, the page asks again by itself when the
/// connection returns). An unknown slug is a "not found" empty state; a
/// failure with no card to show is the full-screen "No connection" / error
/// view. A failed reload keeps the page and shows a snack bar. A returning
/// connection refreshes the product and its reviews — the reviews too when
/// the product never loaded (their section is not on screen then).
class PdpBody extends StatelessWidget {
  const PdpBody({super.key, this.galleryKey});

  /// Put on the gallery, for the buy bar's fly-to-cart.
  final GlobalKey? galleryKey;

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () async {
        await Future.wait([
          context.read<ProductDetailCubit>().onReconnected(),
          context.read<ProductReviewsCubit>().onReconnected(),
        ]);
      },
      child: ScreenFailureListener<ProductDetailCubit, ProductDetailState>(
        child: BlocBuilder<ProductDetailCubit, ProductDetailState>(
          // The gallery page and the basket have their own builders: never
          // rebuild the whole page for them.
          buildWhen: (previous, current) =>
              current.load.screenChangedFrom(previous.load) ||
              previous.detail != current.detail ||
              previous.selectedVariantId != current.selectedVariantId,
          builder: (context, state) {
            final cubit = context.read<ProductDetailCubit>();
            final detail = state.detail;
            if (detail != null) {
              return PdpLoadedView(
                detail: detail,
                selectedVariantId: state.selectedVariantId,
                lowStockLeft: state.lowStockLeft,
                galleryKey: galleryKey,
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
            final preview = state.preview;
            final failed = state.status == LoadPhase.error;
            if (preview == null) {
              return SafeArea(
                child: failed
                    ? FailureView(failure: state.failure, onRetry: cubit.load)
                    : const AppLoader(),
              );
            }
            return PdpPreviewView(
              preview: preview,
              galleryKey: galleryKey,
              footer: failed
                  ? PdpLoadFailure(failure: state.failure, onRetry: cubit.load)
                  : const Padding(
                      padding: EdgeInsets.all(AppSpacing.s24),
                      child: AppLoader.inline(),
                    ),
            );
          },
        ),
      ),
    );
  }
}
