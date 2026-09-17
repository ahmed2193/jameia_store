import 'package:flutter/material.dart';

import '../../config/theme/app_colors.dart';
import 'branded_loader.dart';

/// Branded Jameia loader (brand-yellow dot pulse). Was a bare
/// [CircularProgressIndicator]; now routes through [BrandedLoader] so every
/// loading spot in the app shares the brand look. Inline-sized loaders use the
/// cheap painted dots; pass a larger [size] for block loads.
class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.size = 28});
  final double size;
  @override
  Widget build(BuildContext context) => Center(
    child: BrandedLoader.inline(size: size * 1.6, color: AppColors.primary),
  );
}
