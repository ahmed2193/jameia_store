import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../core/domain/entities/jameia_address_entity.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/utils/address_display.dart';
import '../../../../core/utils/failure_message.dart';
import '../../../address/presentation/cubit/address_book_cubit.dart';
import '../../../address/presentation/cubit/address_book_state.dart';
import '../../../notifications/presentation/cubit/unread_notifications_cubit.dart';
import '../../../notifications/presentation/cubit/unread_notifications_state.dart';
import 'home_hero_delegate.dart';

/// The home hero header. Its delivery pill always shows the customer's
/// default saved address, live from the app-global address book; without one
/// (a guest, an empty book) it falls back to the store's delivery area, then
/// to a prompt. Tapping the pill opens the saved addresses, and the one the
/// customer picks becomes the default.
class HomeHeaderSliver extends StatelessWidget {
  const HomeHeaderSliver({super.key, required this.fallbackPlace});

  /// The delivery area the store knows (`GET /v1/init`); empty when unknown.
  final String fallbackPlace;

  Future<void> _pickAddress(BuildContext context) async {
    final addressBook = context.read<AddressBookCubit>();
    final picked = await context.push<Object?>(Routes.addressList);
    if (picked is! JameiaAddressEntity) return;
    final failure = await addressBook.makeDefault(picked.id);
    if (failure != null && context.mounted) {
      showJameiaSnackBar(context, failure.localizedMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds only when the default address or the unread badge changes.
    return BlocSelector<
      AddressBookCubit,
      AddressBookState,
      JameiaAddressEntity?
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
                placeLabel:
                    defaultAddress?.shortPlace ??
                    (fallbackPlace.isNotEmpty
                        ? fallbackPlace
                        : 'home.choose_delivery_area'.tr()),
                topPad: MediaQuery.paddingOf(context).top,
                onAddressTap: () => _pickAddress(context),
                onSearch: () => context.push(Routes.search),
                onNotifications: () => context.push(Routes.notifications),
                hasUnreadNotifications: hasUnread,
              ),
            ),
          ),
    );
  }
}
