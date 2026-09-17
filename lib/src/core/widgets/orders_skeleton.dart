import 'package:flutter/material.dart';

import 'list_skeleton.dart';

/// Orders-list skeleton.
class OrdersSkeleton extends StatelessWidget {
  const OrdersSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const ListSkeleton(count: 4);
}
