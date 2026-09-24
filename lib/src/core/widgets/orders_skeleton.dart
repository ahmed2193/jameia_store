import 'package:flutter/material.dart';

import 'product_row_skeleton.dart';

/// Orders-list skeleton. A non-scrolling list rather than a fixed column: in
/// the Cart tab the orders sit under the tab's switch and above the bottom
/// nav, and four rows are taller than that space on a small phone — a column
/// overflowed there, a list just clips the last row.
class OrdersSkeleton extends StatelessWidget {
  const OrdersSkeleton({super.key});

  static const int _rows = 4;

  @override
  Widget build(BuildContext context) => ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _rows,
    itemBuilder: (_, _) => const ProductRowSkeleton(),
  );
}
