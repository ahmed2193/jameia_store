import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../../config/theme/app_shadows.dart';
import '../../config/theme/app_spacing.dart';

/// The white sheet of a brand sheet page: rounded top corners, a soft
/// shadow up onto the green, and [child] clipped to its shape (so content
/// scrolled under the corners never shows past them).
class BrandSheetSurface extends StatelessWidget {
  const BrandSheetSurface({super.key, required this.child});

  static const BorderRadius corners = BorderRadius.vertical(
    top: Radius.circular(AppRadius.sheet),
  );

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: corners,
        boxShadow: AppShadows.barTop,
      ),
      child: ClipRRect(borderRadius: corners, child: child),
    );
  }
}
