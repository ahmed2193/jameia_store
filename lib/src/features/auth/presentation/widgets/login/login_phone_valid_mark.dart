import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/motion_widgets.dart';
import '../../../../../core/motion/spring_curve.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../../../core/widgets/hero_icon.dart';
import '../../cubit/login_cubit.dart';
import '../../cubit/login_state.dart';

/// The green check at the end of the phone unit: it springs in the moment
/// the eighth digit makes the number valid (the page adds one selection
/// haptic) and leaves when it is not. Its slot is always reserved, so the
/// number never shifts.
class LoginPhoneValidMark extends StatelessWidget {
  const LoginPhoneValidMark({super.key});

  static const double _slot = AppSize.s24;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _slot,
      child: BlocSelector<LoginCubit, LoginState, bool>(
        selector: (state) => state.phone.isValid,
        builder: (context, valid) => valid
            ? PopScale.onMount(
                curve: AppSprings.snappy,
                duration: AppSprings.snappy.duration,
                child: const HeroIcon(
                  HeroIcons.checkCircle,
                  size: AppSize.s22,
                  color: AppColors.primaryDark,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
