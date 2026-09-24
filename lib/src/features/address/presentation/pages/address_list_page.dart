import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../core/navigation/navigation.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/utils/failure_message.dart';
import '../cubit/address_book_cubit.dart';
import '../cubit/address_book_state.dart';
import '../widgets/address_list/address_add_bar.dart';
import '../widgets/address_list/address_list_app_bar.dart';
import '../widgets/address_list/address_list_body.dart';

/// Mine → "My addresses" (also the address picker from Home: a tapped row
/// pops the route with that address).
///
/// Reads the app-global `AddressBookCubit`, which already holds the book
/// (device copy + a sync on sign-in), so the list is instant. Opening the
/// page syncs only when this session has not reached the server yet (launch
/// offline, a guest → sign-in prompt).
class AddressListPage extends StatefulWidget {
  const AddressListPage({super.key});

  @override
  State<AddressListPage> createState() => _AddressListPageState();
}

class _AddressListPageState extends State<AddressListPage> {
  @override
  void initState() {
    super.initState();
    unawaited(context.read<AddressBookCubit>().ensureSynced());
  }

  static bool _listenWhen(
    AddressBookState previous,
    AddressBookState current,
  ) =>
      current.deleted ||
      (current.failure != null && previous.failure != current.failure);

  void _onState(BuildContext context, AddressBookState state) {
    if (state.deleted) {
      showJameiaSnackBar(context, 'addr.deleted'.tr());
      return;
    }
    final failure = state.failure;
    // A failed first load / the sign-in prompt is rendered by the body.
    if (failure == null || !state.isLoaded) return;
    showJameiaSnackBar(context, failure.localizedMessage);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddressBookCubit, AddressBookState>(
      listenWhen: _listenWhen,
      listener: _onState,
      child: const Scaffold(
        backgroundColor: AppColors.mediumBackground,
        appBar: AddressListAppBar(),
        body: SafeArea(
          top: false,
          child: ContentClamp(child: AddressListBody()),
        ),
        bottomNavigationBar: AddressAddBar(),
      ),
    );
  }
}
