import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/widgets/jameia_title_bar.dart';
import '../../cubit/checkout_cubit.dart';

/// The checkout's app bar: "Checkout" over a grey `{store} · {branch}` line
/// (the store's name from `GET /v1/init`, the serving branch from the
/// delivery selection). Only what is known is shown: one of the two alone,
/// or no second line at all — a name is never invented.
class CheckoutTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const CheckoutTitleBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(JameiaTitleBar.height);

  @override
  Widget build(BuildContext context) {
    final (store, branch) = context.select<CheckoutCubit, (String, String)>(
      (cubit) => (
        cubit.state.rules.storeName,
        cubit.state.selection?.branchName ?? '',
      ),
    );
    final subtitle = store.isNotEmpty && branch.isNotEmpty
        ? 'checkout.subtitle_store_branch'.tr(
            namedArgs: {'store': store, 'branch': branch},
          )
        : store.isNotEmpty
        ? store
        : branch;
    return JameiaTitleBar(title: 'checkout.title'.tr(), subtitle: subtitle);
  }
}
