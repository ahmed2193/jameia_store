import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/hero_assets.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../../../../config/theme/app_text_styles.dart';
import '../../../../core/domain/entities/screen_load.dart';
import '../../../../core/navigation/screen_failure_listener.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/reconnect_refresh.dart';
import '../../../../core/widgets/screen_stale_notice.dart';
import '../../../../core/widgets/state_views.dart';
import '../cubit/content_page_cubit.dart';
import '../cubit/content_page_state.dart';

/// Body of a CMS page: loader, the backend's text (the saved one at once,
/// with the "Updated … ago" note while offline or after a failed reload),
/// empty, error + retry or "No connection" when nothing is saved. A failed
/// reload is told the shared way (offline: only the banner). A returning
/// connection refreshes a saved or failed page.
class ContentPageBody extends StatelessWidget {
  const ContentPageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return ReconnectRefresh(
      onReconnected: () => context.read<ContentPageCubit>().onReconnected(),
      child: ScreenFailureListener<ContentPageCubit, ContentPageState>(
        child: BlocBuilder<ContentPageCubit, ContentPageState>(
          buildWhen: (previous, current) =>
              current.load.screenChangedFrom(previous.load) ||
              previous.page != current.page,
          builder: (context, state) {
            final page = state.page;
            if (page == null) {
              return state.status == LoadPhase.error
                  ? FailureView(
                      failure: state.failure,
                      onRetry: context.read<ContentPageCubit>().load,
                    )
                  : const AppLoader();
            }
            if (page.isEmpty) {
              return HeroStateView(
                message: 'content.empty'.tr(),
                art: HeroAssets.stateNotFound,
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ScreenStaleNotice<ContentPageCubit, ContentPageState>(),
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
      ),
    );
  }
}
