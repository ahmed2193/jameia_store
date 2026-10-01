import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/widgets/hero_title_bar.dart';
import '../cubit/customer_service_question_cubit.dart';
import '../widgets/topics/support_topics_body.dart';

/// Hero FAQ page — `mach_pro_sailor_c_customer_service_question`: the help
/// topics filtered as the customer types, each an expandable question →
/// answer, and a "Still need help?" card into the chat.
///
/// [arg] optionally carries the topic (or an order id / a search text) the
/// hub was opened with; a matching topic starts open.
class CustomerServiceQuestionPage extends StatelessWidget {
  const CustomerServiceQuestionPage({super.key, this.arg});

  final String? arg;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CustomerServiceQuestionCubit>()..load(),
      child: Scaffold(
        backgroundColor: AppColors.mediumBackground,
        appBar: HeroTitleBar(title: 'support.title_help_topics'.tr()),
        body: SupportTopicsBody(initialQuestion: arg),
      ),
    );
  }
}
