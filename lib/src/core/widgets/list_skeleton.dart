import 'package:flutter/material.dart';

import 'product_row_skeleton.dart';

/// Generic list skeleton — N [ProductRowSkeleton]s. Used for shop menu, coupons,
/// orders, search results.
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.count = 6});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List<Widget>.generate(count, (_) => const ProductRowSkeleton()),
    );
  }
}
