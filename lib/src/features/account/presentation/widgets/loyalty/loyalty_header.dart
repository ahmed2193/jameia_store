import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/loyalty_entry_entity.dart';
import '../../../domain/entities/loyalty_program.dart';
import '../../cubit/ledger_cubit.dart';
import '../../cubit/ledger_state.dart';
import '../../cubit/loyalty_program_cubit.dart';
import '../ledger/ledger_balance_card.dart';
import '../ledger/ledger_section_title.dart';
import 'loyalty_rules_card.dart';

/// Points balance (+ what it is worth), the programme rules when the store
/// runs one, and the history title.
class LoyaltyHeader extends StatelessWidget {
  const LoyaltyHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LoyaltyProgramCubit, LoyaltyProgram>(
      builder: (context, program) =>
          BlocSelector<
            LedgerCubit<LoyaltyEntryEntity>,
            LedgerState<LoyaltyEntryEntity>,
            int
          >(
            selector: (state) => state.ledger.balance,
            builder: (context, points) {
              final worthKd = program.valueKdOf(points);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LedgerBalanceCard(
                    icon: Icons.stars_rounded,
                    label: 'loyalty.balance'.tr(),
                    value: 'loyalty.points_value'.tr(
                      namedArgs: {'points': '$points'},
                    ),
                    caption: worthKd > 0
                        ? 'loyalty.worth'.tr(
                            namedArgs: {'amount': Formatters.price(worthKd)},
                          )
                        : '',
                  ),
                  if (program.enabled) LoyaltyRulesCard(program: program),
                  LedgerSectionTitle('loyalty.history'.tr()),
                ],
              );
            },
          ),
    );
  }
}
