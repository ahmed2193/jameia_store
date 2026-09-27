import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../core/domain/entities/hero_address_entity.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/utils/address_display.dart';
import '../../../address/presentation/cubit/address_book_cubit.dart';
import '../../../address/presentation/cubit/address_book_state.dart';
import '../../../assistant/presentation/cubit/assistant_availability_cubit.dart';
import '../../../notifications/presentation/cubit/unread_notifications_cubit.dart';
import '../../../notifications/presentation/cubit/unread_notifications_state.dart';
import '../../../store_mode/presentation/cubit/pro_status_cubit.dart';
import '../../domain/entities/home_bootstrap.dart';
import 'home_hero_delegate.dart';

/// The home header. The store row comes from the launch snapshot (name, the
/// zone's delivery time), with the "pro" tag of a Hero Pro member (the
/// app-global Pro status — a guest, a non-member and a status not known yet
/// see the plain store name). The delivery line always shows the
/// customer's default saved address, live from the app-global address book;
/// without one (a guest, an empty book) it falls back to the store's
/// delivery area, then to a prompt. Tapping it opens the saved addresses, and
/// the one the customer picks becomes the default. The assistant disc shows
/// while the store runs the assistant.
class HomeHeaderSliver extends StatelessWidget {
  const HomeHeaderSliver({super.key, required this.bootstrap});

  /// The launch snapshot (`GET /v1/init`); empty until it lands.
  final HomeBootstrap bootstrap;

  Future<void> _pickAddress(BuildContext context) async {
    final addressBook = context.read<AddressBookCubit>();
    final picked = await context.push<Object?>(Routes.addressList);
    if (picked is! HeroAddressEntity) return;
    final failure = await addressBook.makeDefault(picked.id);
    if (failure != null && context.mounted) {
      showFailureSnackBar(context, failure, action: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final delivery = bootstrap.delivery;
    final fallbackPlace = delivery?.placeName ?? '';
    final showAssistant = context.select<AssistantAvailabilityCubit, bool>(
      (availability) => availability.state.isAvailable,
    );
    // The "pro" tag is the member's: it pops in when the perks switch on.
    final isMember = context.select<ProStatusCubit, bool>(
      (status) => status.state.membership.hasBenefits,
    );
    // Rebuilds only when the default address or the unread badge changes.
    return BlocSelector<
      AddressBookCubit,
      AddressBookState,
      HeroAddressEntity?
    >(
      selector: (state) => state.book.defaultAddress,
      builder: (context, defaultAddress) =>
          BlocSelector<
            UnreadNotificationsCubit,
            UnreadNotificationsState,
            bool
          >(
            selector: (unread) => unread.hasUnread,
            builder: (context, hasUnread) => SliverPersistentHeader(
              pinned: true,
              delegate: HomeHeroDelegate(
                storeName: bootstrap.storeName.isNotEmpty
                    ? bootstrap.storeName
                    : 'home.hero'.tr(),
                isPro: isMember,
                etaMinutes: delivery?.etaMinutes ?? 0,
                placeLabel:
                    defaultAddress?.shortPlace ??
                    (fallbackPlace.isNotEmpty
                        ? fallbackPlace
                        : 'home.choose_delivery_area'.tr()),
                topPad: MediaQuery.paddingOf(context).top,
                textScaler: MediaQuery.textScalerOf(context),
                onAddressTap: () => _pickAddress(context),
                onSearch: () => context.push(Routes.search),
                onNotifications: () => context.push(Routes.notifications),
                hasUnreadNotifications: hasUnread,
                onAssistant: showAssistant
                    ? () => context.push(Routes.assistant)
                    : null,
              ),
            ),
          ),
    );
  }
}
