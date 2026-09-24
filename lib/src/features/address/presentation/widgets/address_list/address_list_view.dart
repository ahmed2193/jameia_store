import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/widgets/branded_refresh.dart';
import '../../../domain/entities/address_book.dart';
import '../../cubit/address_book_cubit.dart';
import 'address_row.dart';

/// The book as one white grouped card (RE §5), built lazily. Rows are keyed
/// by address id, so a delete or a sync keeps every other row's element.
class AddressListView extends StatelessWidget {
  const AddressListView({super.key, required this.book});

  final AddressBook book;

  @override
  Widget build(BuildContext context) {
    final addresses = book.addresses;
    final lastIndex = addresses.length - 1;
    final indexById = <String, int>{
      for (var index = 0; index < addresses.length; index++)
        addresses[index].id: index,
    };
    return BrandedRefresh(
      onRefresh: () => context.read<AddressBookCubit>().refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.s12),
        itemCount: addresses.length,
        findChildIndexCallback: (key) =>
            key is ValueKey<String> ? indexById[key.value] : null,
        itemBuilder: (_, index) => AddressRow(
          key: ValueKey<String>(addresses[index].id),
          address: addresses[index],
          index: index,
          isFirst: index == 0,
          isLast: index == lastIndex,
        ),
      ),
    );
  }
}
