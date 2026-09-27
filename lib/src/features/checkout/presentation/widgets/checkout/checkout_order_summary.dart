import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../cart/presentation/cubit/cart_cubit.dart';
import 'checkout_issue_banner.dart';
import 'checkout_items_sheet.dart';
import 'checkout_section.dart';
import 'checkout_sheet_frame.dart';
import 'checkout_thumbs_strip.dart';
import 'checkout_ui_controller.dart';

/// "Order summary": an "items unavailable" banner when the server flagged a
/// line, then the strip of pictures with "N pcs ›". A tap on either — or a
/// blocked "Place order" asking through
/// [CheckoutUiController.itemsRequests] — opens the "Total N pcs" sheet with
/// every line.
class CheckoutOrderSummary extends StatefulWidget {
  const CheckoutOrderSummary({super.key});

  @override
  State<CheckoutOrderSummary> createState() => _CheckoutOrderSummaryState();
}

class _CheckoutOrderSummaryState extends State<CheckoutOrderSummary> {
  /// A basket longer than this opens the sheet with the slower slide of a
  /// tall sheet.
  static const int _largeAfter = 8;

  late final CheckoutUiController _ui;

  /// The sheet is up: a second request (a banner tap racing a blocked
  /// "Place order") never stacks a second one.
  bool _sheetOpen = false;

  @override
  void initState() {
    super.initState();
    _ui = context.read<CheckoutUiController>()
      ..itemsRequests.addListener(_openItems);
  }

  @override
  void dispose() {
    _ui.itemsRequests.removeListener(_openItems);
    super.dispose();
  }

  void _openItems() {
    if (_sheetOpen || !mounted) return;
    _sheetOpen = true;
    final lines = context.read<CartCubit>().state.cart.lines.length;
    CheckoutSheetFrame.show<void>(
      context,
      large: lines > _largeAfter,
      builder: (_) => const CheckoutItemsSheet(),
    ).whenComplete(() => _sheetOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    return CheckoutSection(
      title: 'checkout.order_summary_title'.tr(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckoutIssueBanner(onReview: _openItems),
          CheckoutThumbsStrip(onTap: _openItems),
        ],
      ),
    );
  }
}
