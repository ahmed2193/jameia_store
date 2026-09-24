import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../../../../config/theme/app_colors.dart';
import '../../domain/entities/loyalty_entry_entity.dart';
import '../cubit/ledger_cubit.dart';
import '../cubit/loyalty_program_cubit.dart';
import '../widgets/ledger/ledger_app_bar.dart';
import '../widgets/ledger/ledger_body.dart';
import '../widgets/ledger/ledger_failure_listener.dart';
import '../widgets/loyalty/loyalty_entry_tile.dart';
import '../widgets/loyalty/loyalty_header.dart';

/// Mine → Loyalty points: the balance, the store's programme rules (`GET
/// /v1/init` → `store.loyalty`) and the points history (`GET
/// /v1/account/loyalty`, signed-in only, paginated).
class LoyaltyPage extends StatelessWidget {
  const LoyaltyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<LedgerCubit<LoyaltyEntryEntity>>()..load(),
        ),
        BlocProvider(create: (_) => sl<LoyaltyProgramCubit>()..load()),
      ],
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: LedgerAppBar(title: 'loyalty.title'.tr()),
        body: LedgerFailureListener<LoyaltyEntryEntity>(
          loadMoreFailedMessage: 'loyalty.load_more_failed'.tr(),
          child: LedgerBody<LoyaltyEntryEntity>(
            header: const LoyaltyHeader(),
            entryBuilder: (entry) => LoyaltyEntryTile(entry: entry),
            emptyIcon: Icons.stars_outlined,
            emptyMessage: 'loyalty.empty'.tr(),
            signInMessage: 'loyalty.sign_in_prompt'.tr(),
          ),
        ),
      ),
    );
  }
}
