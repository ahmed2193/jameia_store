import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/data_freshness.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/cubit_stale_notice.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/content_page_cubit.dart';
import '../cubit/content_page_state.dart';

/// Body of a CMS page: loader, the backend's text (the saved one at once,
/// with the "Updated … ago" note while offline or after a failed reload),
/// empty, error + retry or "No connection" when nothing is saved. A
/// returning connection refreshes a saved or failed page.
class ContentPageBody extends StatelessWidget {
  const ContentPageBody({super.key});

  static DataFreshness _freshnessOf(ContentPageState state) => state.freshness;

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () => context.read<ContentPageCubit>().onReconnected(),
      child: BlocBuilder<ContentPageCubit, ContentPageState>(
        buildWhen: (previous, current) =>
            previous.status != current.status || previous.page != current.page,
        builder: (context, state) {
          final page = state.page;
          if (page == null) {
            return state.status == ContentPageStatus.error
                ? FailureView(
                    failure: state.failure,
                    onRetry: context.read<ContentPageCubit>().load,
                  )
                : const AppLoader();
          }
          if (page.isEmpty) {
            return EmptyStateView(
              message: 'content.empty'.tr(),
              icon: Icons.article_outlined,
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CubitStaleNotice<ContentPageCubit, ContentPageState>(
                  freshnessOf: _freshnessOf,
                ),
                SelectableText(
                  page.body,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryText,
                    height: AppSize.lh1_5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
