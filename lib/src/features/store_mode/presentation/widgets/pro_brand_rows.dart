import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/theme/app_spacing.dart';
import '../../../../core/motion/collapse_reveal.dart';
import '../cubit/pro_brands_cubit.dart';
import '../cubit/pro_brands_state.dart';
import 'pro_brand_marquee.dart';

/// Two drifting rows of brand logos (the second runs the other way, starting
/// on another brand); nothing at all while there is no brand to show. The
/// brands arrive after the page: the rows open their room ([CollapseReveal])
/// instead of snapping in under the perks.
class ProBrandRows extends StatelessWidget {
  const ProBrandRows({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProBrandsCubit, ProBrandsState>(
      builder: (context, state) {
        final brands = state.brands;
        return CollapseReveal(
          visible: brands.isNotEmpty,
          child: brands.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsetsDirectional.only(
                    top: AppSpacing.s20,
                  ),
                  child: Column(
                    spacing: AppSpacing.s12,
                    children: [
                      ProBrandMarquee(brands: brands),
                      ProBrandMarquee(
                        brands: brands,
                        reverse: true,
                        shift: brands.length ~/ 2,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
