import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/collapse_reveal.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../domain/entities/loyalty_entry_entity.dart';
import '../../../../../core/domain/entities/loyalty_program.dart';
import '../../cubit/ledger_cubit.dart';
import '../../cubit/ledger_state.dart';
import '../../cubit/loyalty_program_cubit.dart';
import '../ledger/ledger_balance_card.dart';
import '../ledger/ledger_section_title.dart';
import 'loyalty_rewards_entry.dart';
import 'loyalty_rules_card.dart';

/// Points balance (+ what it is worth), the way to the Rewards screen and
/// the programme rules when the store runs one, and the history title. The
/// programme is read after the page: its blocks open their room
/// ([CollapseReveal]) instead of snapping in over the history.
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
                    icon: HeroIcons.points,
                    label: 'loyalty.balance'.tr(),
                    value: points,
                    valueText: (number) => 'loyalty.points_value'.tr(
                      namedArgs: {'points': number},
                    ),
                    caption: worthKd > 0
                        ? 'loyalty.worth'.tr(
                            namedArgs: {'amount': Formatters.price(worthKd)},
                          )
                        : '',
                  ),
                  CollapseReveal(
                    visible: program.enabled,
                    child: program.enabled
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const LoyaltyRewardsEntry(),
                              LoyaltyRulesCard(program: program),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                  LedgerSectionTitle('loyalty.history'.tr()),
                ],
              );
            },
          ),
    );
  }
}
