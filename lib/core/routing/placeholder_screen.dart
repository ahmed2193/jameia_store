import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Temporary destination for routes whose screen is not yet implemented. Replaced
/// arm-by-arm as feature screens land.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded,
                size: 56, color: AppColors.primary),
            const SizedBox(height: 12),
            Text('$title\ncoming soon',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.secondaryText)),
          ],
        ),
      ),
    );
  }
}
