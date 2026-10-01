import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/domain/entities/screen_load.dart';
import '../../../../../core/widgets/app_loader.dart';
import '../../../../../core/widgets/connectivity_scope.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../../../../core/widgets/load_more_offline_note.dart';
import '../../cubit/product_listing_cubit.dart';
import '../../cubit/product_listing_state.dart';

/// Tail of a paginated grid: a loader while the next page is coming, a retry
/// row when it failed — offline, "more will load when you're back" instead
/// (the list asks again by itself on reconnect) — nothing otherwise. It
/// selects the next page's progress itself, so the grid above never
/// rebuilds for it.
class ListingLoadMoreFooter extends StatelessWidget {
  const ListingLoadMoreFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ProductListingCubit, ProductListingState, NextPageLoad>(
      selector: (state) => state.load.nextPage,
      builder: (context, nextPage) {
        final failed = nextPage == NextPageLoad.failed;
        if (failed && ConnectivityScope.isOfflineOf(context)) {
          return const LoadMoreOfflineNote();
        }
        if (failed) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Center(
              child: TextButton.icon(
                onPressed: () =>
                    context.read<ProductListingCubit>().loadMore(retry: true),
                icon: const HeroIcon(HeroIcons.refresh, color: AppColors.link),
                label: Text(
                  'retry'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.link,
                  ),
                ),
              ),
            ),
          );
        }
        if (nextPage != NextPageLoad.loading) return const SizedBox.shrink();
        return const Padding(
          padding: EdgeInsets.all(AppSpacing.s16),
          child: AppLoader.inline(),
        );
      },
    );
  }
}
