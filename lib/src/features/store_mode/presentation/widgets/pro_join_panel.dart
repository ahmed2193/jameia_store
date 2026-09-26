import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../config/theme/app_spacing.dart';
import '../cubit/pro_membership_cubit.dart';
import 'pro_join_button.dart';
import 'pro_trust_band.dart';

/// Foot of the paywall under the account strip: the full-width trust band,
/// then the CTA on white — only the terms band for a member. Clears the
/// device's bottom inset.
class ProJoinPanel extends StatelessWidget {
  const ProJoinPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final isMember = context.select<ProMembershipCubit, bool>(
      (cubit) => cubit.state.isMember,
    );
    final inset = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: AppColors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProTrustBand(termsOnly: isMember),
          if (isMember)
            SizedBox(height: inset)
          else
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                AppSpacing.s16,
                AppSpacing.s12,
                AppSpacing.s16,
                AppSpacing.s12 + inset,
              ),
              child: const ProJoinButton(),
            ),
        ],
      ),
    );
  }
}
