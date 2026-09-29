import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/shell_arrival.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';

/// The round white button at the top start of the sign-in pages, over the
/// green header. Back to the page that opened sign-in when there is one;
/// otherwise — sign-in is the whole stack, after signing out or an expired
/// session — a close that lets the customer keep browsing as a guest (the
/// shell, with `go`, so its cubits start fresh). `Icons.arrow_back` mirrors
/// under RTL on its own.
class AuthTopButton extends StatelessWidget {
  const AuthTopButton({super.key});

  static const double diameter = AppSize.s40;

  @override
  Widget build(BuildContext context) {
    final canPop = context.canPop();
    final labels = MaterialLocalizations.of(context);
    return PressScale(
      pressedScale: AppMotion.pressedScaleSmall,
      child: IconButton(
        tooltip: canPop ? labels.backButtonTooltip : labels.closeButtonTooltip,
        onPressed: () => canPop
            ? context.pop()
            : context.go(Routes.shell, extra: ShellArrival()),
        style: IconButton.styleFrom(
          fixedSize: const Size.square(diameter),
          minimumSize: const Size.square(diameter),
          backgroundColor: AppColors.white,
          foregroundColor: AppColors.primaryText,
        ),
        icon: Icon(
          canPop ? Icons.arrow_back : Icons.close_rounded,
          size: AppSize.s22,
        ),
      ),
    );
  }
}
