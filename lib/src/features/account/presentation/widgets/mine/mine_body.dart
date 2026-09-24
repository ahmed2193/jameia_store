import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/responsive/content_clamp.dart';
import '../../../../auth/presentation/cubit/auth_session_cubit.dart';
import '../../../../auth/presentation/cubit/auth_session_state.dart';
import '../../../../notifications/presentation/cubit/unread_notifications_cubit.dart';
import '../../../../notifications/presentation/cubit/unread_notifications_state.dart';
import '../../cubit/account_cubit.dart';
import 'mine_delivery_code_cell.dart';
import 'mine_invite_banner.dart';
import 'mine_menu_group.dart';
import 'mine_profile_header.dart';
import 'mine_quick_stats_row.dart';

/// The Mine tab content: header, quick stats, invite banner, menu, delivery
/// code. Section gaps are 12dp (bundle `b94ec7`), 24dp at the bottom
/// (`aeff4d`).
class MineBody extends StatelessWidget {
  const MineBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountCubit, AccountState>(
      builder: (context, state) {
        final user = state.user;
        // Brief in-memory load — the overview resolves within a frame.
        if (user == null) return const SizedBox.shrink();
        return CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(
              child: StaggerEntrance(index: 0, child: MineProfileHeader()),
            ),
            SliverToBoxAdapter(
              child: ContentClamp(
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.s12),
                    // Wallet balance comes from the signed-in customer
                    // (fils); guests see zero.
                    BlocSelector<AuthSessionCubit, AuthSessionState, double>(
                      selector: (session) => session.customer?.walletKd ?? 0,
                      builder: (context, walletKd) => StaggerEntrance(
                        index: 1,
                        child: MineQuickStatsRow(
                          coupons: state.couponCount,
                          favourites: state.favouriteCount,
                          walletKd: walletKd,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    const StaggerEntrance(index: 2, child: MineInviteBanner()),
                    const SizedBox(height: AppSpacing.s12),
                    // customerServiceUnread drives the badge on the "Customer
                    // service" cell (offline stub; 0 would hide the badge).
                    // The group's cells stagger individually inside
                    // [MineMenuGroup], so the group itself is not re-wrapped.
                    BlocSelector<
                      UnreadNotificationsCubit,
                      UnreadNotificationsState,
                      int
                    >(
                      selector: (unread) => unread.unreadCount,
                      builder: (context, notificationsUnread) => MineMenuGroup(
                        customerUnreadCount: state.customerServiceUnread,
                        notificationsUnread: notificationsUnread,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    StaggerEntrance(
                      index: 4,
                      child: MineDeliveryCodeCell(code: user.deliveryCode),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
