import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/widgets/skeletons.dart';

/// Placeholder rows while the first sync runs with nothing cached. Rows that
/// do not fit a short screen are clipped instead of overflowing.
class AddressListSkeleton extends StatelessWidget {
  const AddressListSkeleton({super.key});

  static const int _rows = 4;

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(AppSpacing.s12),
      child: Skeletonized(loading: true, child: ListSkeleton(count: _rows)),
    );
  }
}
