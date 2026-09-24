import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/offers_cubit.dart';
import '../widgets/marketing_app_bar.dart';
import '../widgets/offers_body.dart';

/// The store's active offers (`GET /v1/offers`) — the automatic promotions the
/// backend applies to the cart. Offer text arrives resolved for the request
/// language, so a language switch reloads.
class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OffersCubit>(
      create: (_) => sl<OffersCubit>()..load(),
      child: Builder(
        builder: (context) =>
            BlocListener<LocalizationCubit, LocalizationState>(
              listenWhen: (previous, current) =>
                  previous.locale != current.locale,
              listener: (context, _) => context.read<OffersCubit>().load(),
              child: Scaffold(
                backgroundColor: AppColors.mediumBackground,
                appBar: MarketingAppBar(title: 'offers.title'.tr()),
                body: const OffersBody(),
              ),
            ),
      ),
    );
  }
}
