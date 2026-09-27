import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/routes/routes.dart';
import '../../../../core/widgets/collection_frame.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../../language/presentation/cubit/localization_state.dart';
import '../cubit/offers_cubit.dart';
import '../widgets/offers_body.dart';
import '../widgets/offers_cart_bar.dart';

/// The store's active offers (`GET /v1/offers`) — the automatic promotions the
/// backend applies to the cart — as a Hero collection page: the store's
/// name in a top bar over a cream hero, the offers as flat cards, and the
/// "View cart" pill once the basket has items. Offer text arrives resolved
/// for the request language, so a language switch reloads.
class OffersPage extends StatelessWidget {
  const OffersPage({super.key});

  static const String _emoji = '🔥';

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OffersCubit>(
      create: (_) => sl<OffersCubit>()..load(),
      child: BlocListener<LocalizationCubit, LocalizationState>(
        listenWhen: (previous, current) => previous.locale != current.locale,
        listener: (context, _) => context.read<OffersCubit>().load(),
        child: CollectionFrame(
          storeName: 'core.store_name'.tr(),
          heading: 'offers.hero_title'.tr(),
          emoji: _emoji,
          subtitle: 'offers.hero_subtitle'.tr(),
          onBack: context.canPop() ? context.pop : null,
          onSearch: () => context.push(Routes.search),
          bottomBar: const OffersCartBar(),
          bodyBuilder: (context, headerSlivers) =>
              OffersBody(headerSlivers: headerSlivers),
        ),
      ),
    );
  }
}
