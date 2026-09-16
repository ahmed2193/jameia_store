import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Contact-rider button (`detailpage_contact_rider`) — filled = call, outline =
/// chat. No-ops here (dummy data, no telephony).
class ContactAction extends StatelessWidget {
  const ContactAction({
    super.key,
    required this.icon,
    required this.filled,
    this.onTap,
  });
  final IconData icon;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.white,
          shape: BoxShape.circle,
          border: filled
              ? null
              : Border.all(color: AppColors.divider, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: filled ? AppColors.black : AppColors.primaryText,
        ),
      ),
    );
  }
}
