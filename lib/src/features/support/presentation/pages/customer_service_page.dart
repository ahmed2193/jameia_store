import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/widgets/hero_title_bar.dart';
import '../cubit/customer_service_cubit.dart';
import '../widgets/hub/customer_service_body.dart';

/// Hero customer-service help-center hub — `mach_pro_sailor_c_customer_service`:
/// a recent-order help card, a search entry, the FAQ topics (→
/// `customer_service_question`), a hotline row and a chat-with-support button.
class CustomerServicePage extends StatelessWidget {
  const CustomerServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CustomerServiceCubit>()..load(),
      child: Scaffold(
        backgroundColor: AppColors.mediumBackground,
        appBar: HeroTitleBar(title: 'support.title_customer_service'.tr()),
        body: const CustomerServiceBody(),
      ),
    );
  }
}
