import 'package:flutter/widgets.dart';

import '../../config/theme/app_colors.dart';
import '../responsive/app_size.dart';
import 'branded_dot_loader.dart';

/// [StateIconPlate]'s twin for a state that is still working it out: the
/// same 88 dp muted circle, holding the branded dots instead of an icon.
class StateLoaderPlate extends StatelessWidget {
  const StateLoaderPlate({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppSize.s88,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.smallBackground,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: BrandedDotLoader(
              size: AppSize.s40,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
