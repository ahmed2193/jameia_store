import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme/app_colors.dart';
import '../responsive/app_size.dart';

/// Plain ✕ for a sheet header or a full-screen flow: a 48 dp target, no fill.
/// Pops the route unless [onPressed] is given.
class JameiaCloseButton extends StatelessWidget {
  const JameiaCloseButton({super.key, this.onPressed, this.color});

  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      onPressed: onPressed ?? () => context.pop(),
      style: IconButton.styleFrom(
        fixedSize: const Size.square(AppSize.s48),
        foregroundColor: color ?? AppColors.primaryText,
      ),
      icon: const Icon(Icons.close_rounded, size: AppSize.s24),
    );
  }
}
