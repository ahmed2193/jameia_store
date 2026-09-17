import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Temporary destination for routes whose screen is not yet implemented (and
/// the GoRouter error page for unknown locations). Replaced route-by-route as
/// feature screens land.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key, required this.title});
  final String title;

  static const String _fallbackTitle = 'Screen';

  /// Derives the placeholder title from a route path: `'/punctual-rule'` ->
  /// `'punctual rule'` (null -> `'Screen'`).
  static String titleFor(String? location) =>
      (location ?? _fallbackTitle).replaceFirst('/', '').replaceAll('-', ' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.construction_rounded,
              size: 56,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              '$title\ncoming soon',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
