import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../../domain/entities/content_page_entity.dart';
import '../cubit/content_page_cubit.dart';
import '../cubit/content_page_state.dart';
import '../widgets/content_page_body.dart';
import '../widgets/marketing_app_bar.dart';

/// A CMS page of the backend (`GET /v1/pages/:slug`): about, contact, FAQ,
/// privacy, terms. Its text arrives resolved for the request language, so a
/// language switch reloads.
class ContentPage extends StatelessWidget {
  const ContentPage({super.key, required this.kind});

  final ContentPageKind kind;

  @override
  Widget build(BuildContext context) {
    final fallbackTitle = switch (kind) {
      ContentPageKind.about => 'content.about'.tr(),
      ContentPageKind.contact => 'content.contact'.tr(),
      ContentPageKind.faq => 'content.faq'.tr(),
      ContentPageKind.privacy => 'content.privacy'.tr(),
      ContentPageKind.terms => 'content.terms'.tr(),
    };
    return BlocProvider<ContentPageCubit>(
      create: (_) => sl<ContentPageCubit>(param1: kind)..load(),
      child: Builder(
        builder: (context) =>
            BlocListener<LocalizationCubit, LocalizationState>(
              listenWhen: (previous, current) =>
                  previous.locale != current.locale,
              listener: (context, _) => context.read<ContentPageCubit>().load(),
              child: Scaffold(
                backgroundColor: AppColors.white,
                appBar: PreferredSize(
                  preferredSize: const Size.fromHeight(kToolbarHeight),
                  child:
                      BlocSelector<ContentPageCubit, ContentPageState, String>(
                        selector: (state) {
                          final title = state.page?.title ?? '';
                          return title.isEmpty ? fallbackTitle : title;
                        },
                        builder: (context, title) =>
                            MarketingAppBar(title: title),
                      ),
                ),
                body: const ContentPageBody(),
              ),
            ),
      ),
    );
  }
}
