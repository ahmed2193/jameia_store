import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/content_page_cubit.dart';
import '../cubit/content_page_state.dart';

/// Body of a CMS page: loader, the backend's text, empty, error + retry
/// (offline = the error view).
class ContentPageBody extends StatelessWidget {
  const ContentPageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContentPageCubit, ContentPageState>(
      buildWhen: (previous, current) =>
          previous.status != current.status || previous.page != current.page,
      builder: (context, state) {
        final page = state.page;
        if (page == null) {
          return state.status == ContentPageStatus.error
              ? ErrorView(
                  message: state.failure?.localizedMessage,
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
          child: SelectableText(
            page.body,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primaryText,
              height: AppSize.lh1_5,
            ),
          ),
        );
      },
    );
  }
}
