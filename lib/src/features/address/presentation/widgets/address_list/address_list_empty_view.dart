import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/design/jameia_icons.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../../../core/widgets/state_views.dart';
import '../../cubit/address_book_cubit.dart';

/// No saved address yet — still pull-to-refresh (an address added on another
/// device shows up).
class AddressListEmptyView extends StatelessWidget {
  const AddressListEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return BrandedRefresh(
      onRefresh: () => context.read<AddressBookCubit>().refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyStateView(
              message: 'addr.no_saved_addresses'.tr(),
              icon: JameiaIcons.locationOutline,
            ),
          ),
        ],
      ),
    );
  }
}
