import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../auth/presentation/cubit/auth_session_state.dart';
import 'mine_header_row.dart';

/// Session-aware Mine header: the signed-in customer (name + phone + the PRO
/// pill, tap → edit profile; "Complete your profile" while the account has
/// no real name yet) or the sign-in prompt for guests (tap → login). Reads
/// the app-global `AuthSessionCubit`; rebuilds only when the customer
/// changes.
class MineProfileHeader extends StatelessWidget {
  const MineProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthSessionCubit, AuthSessionState>(
      buildWhen: (previous, current) =>
          previous.isSignedIn != current.isSignedIn ||
          previous.customer != current.customer,
      builder: (context, session) {
        final customer = session.isSignedIn ? session.customer : null;
        final languageCode = context.locale.languageCode;
        return MineHeaderRow(
          title: customer == null
              ? 'profile.sign_in_title'.tr()
              : customer.needsName
              ? 'profile.complete_profile'.tr()
              : customer.displayNameFor(languageCode),
          // Isolated: the leading `+` of a Kuwaiti number is a neutral
          // character, and an Arabic paragraph pushes it to the far end —
          // the header read `96550001122+`.
          subtitle: customer == null
              ? 'profile.sign_in_subtitle'.tr()
              : Formatters.isolate(customer.phone),
          showEdit: customer != null,
          showProBadge: customer?.isPro ?? false,
          onTap: () => context.push(
            customer != null ? Routes.profileEdit : Routes.login,
          ),
          onScan: () => context.push(Routes.mineDeliveryCode),
        );
      },
    );
  }
}
