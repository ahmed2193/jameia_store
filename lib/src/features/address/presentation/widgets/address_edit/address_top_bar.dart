import 'package:flutter/material.dart';

import '../../../../../config/theme/app_spacing.dart';
import 'circle_button.dart';

/// Top white chrome: a circular leading button + (SELECT) a search box.
class AddressTopBar extends StatelessWidget {
  const AddressTopBar({
    super.key,
    required this.icon,
    required this.onLeading,
    this.search,
  });
  final IconData icon;
  final VoidCallback onLeading;
  final Widget? search;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleButton(icon: icon, onTap: onLeading),
        if (search != null) ...[
          const SizedBox(width: AppSpacing.s12),
          Expanded(child: search!),
        ],
      ],
    );
  }
}
