import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/domain/entities/pro_membership_entity.dart';
import '../../../../assistant/presentation/cubit/assistant_availability_cubit.dart';
import '../../../../notifications/presentation/cubit/unread_notifications_cubit.dart';
import '../../../../store_mode/presentation/cubit/pro_status_cubit.dart';
import '../../cubit/account_cubit.dart';
import 'mine_menu_group.dart';

/// Feeds the Mine menu from the cubits it depends on — the inbox unread
/// badge, the customer-service badge, whether the store runs the Hero
/// Assistant and where the customer stands with Hero Pro. Only this
/// section rebuilds when one of them changes.
class MineMenu extends StatelessWidget {
  const MineMenu({super.key, this.firstEntranceIndex = 0});

  final int firstEntranceIndex;

  @override
  Widget build(BuildContext context) {
    final pro = context
        .select<
          ProStatusCubit,
          ({ProMembershipEntity? membership, bool offered})
        >(
          (status) => (
            membership: status.state.isSettled ? status.state.membership : null,
            offered: status.state.canOffer,
          ),
        );
    return MineMenuGroup(
      firstEntranceIndex: firstEntranceIndex,
      notificationsUnread: context.select<UnreadNotificationsCubit, int>(
        (unread) => unread.state.unreadCount,
      ),
      customerUnreadCount: context.select<AccountCubit, int>(
        (account) => account.state.customerServiceUnread,
      ),
      showAssistant: context.select<AssistantAvailabilityCubit, bool>(
        (availability) => availability.state.isAvailable,
      ),
      proMembership: pro.membership,
      proOffered: pro.offered,
    );
  }
}
