import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/login_args.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/design/hero_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/navigation/sign_in_flow.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/widgets/hero_icon.dart';

/// The round white button at the top start of the sign-in pages, over the
/// green header. Back to the page that opened sign-in when there is one;
/// otherwise — sign-in is the whole stack (signed out, an expired session,
/// a page that asked for it) — a close that lets the customer keep browsing
/// as a guest by the way [args] names ([SignInFlow.leave]: the shell with
/// `go`, so its cubits start fresh, and the page sign-in was opened from).
/// `HeroIcons.back` mirrors under RTL on its own.
class AuthTopButton extends StatelessWidget {
  const AuthTopButton({super.key, this.args = const LoginArgs()});

  static const double diameter = AppSize.s40;

  final LoginArgs args;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();
    final labels = MaterialLocalizations.of(context);
    return PressScale(
      pressedScale: AppMotion.pressedScaleSmall,
      child: IconButton(
        tooltip: canPop ? labels.backButtonTooltip : labels.closeButtonTooltip,
        onPressed: () =>
            canPop ? context.pop() : SignInFlow.leave(context, args),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(diameter),
          minimumSize: const Size.square(diameter),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primaryText,
        ),
        icon: HeroIcon(
          canPop ? HeroIcons.back : HeroIcons.close,
          size: AppSize.s22,
        ),
      ),
    );
  }
}
