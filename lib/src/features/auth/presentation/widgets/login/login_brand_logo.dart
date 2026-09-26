import 'package:flutter/material.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_shadows.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../core/design/jameia_assets.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';

/// The JameiaMart app icon on a white-framed rounded tile. It settles in
/// once per visit — a fade while scaling from [_scaleFrom] to full size — and
/// is decoded at the size it is shown (the source is 1024 px), starting the
/// decode before the first paint.
class LoginBrandLogo extends StatefulWidget {
  const LoginBrandLogo({super.key});

  static const double size = AppSize.s64;

  @override
  State<LoginBrandLogo> createState() => _LoginBrandLogoState();
}

class _LoginBrandLogoState extends State<LoginBrandLogo>
    with SingleTickerProviderStateMixin {
  static const double _scaleFrom = 0.92;
  static const double _frame = AppSize.s2;
  static final BorderRadius _corners = BorderRadius.circular(AppRadius.r3);

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _entrance,
    curve: AppMotion.emphasizedDecelerate,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: _scaleFrom,
    end: 1,
  ).animate(_curve);
  ImageProvider? _image;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_image != null) return;
    final pixels =
        (LoginBrandLogo.size * MediaQuery.devicePixelRatioOf(context)).round();
    final image = ResizeImage(
      const AssetImage(JameiaAssets.appLogo),
      width: pixels,
    );
    _image = image;
    precacheImage(image, context);
    if (MotionGuard.reduced(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return FadeTransition(
      opacity: _curve,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox.square(
          dimension: LoginBrandLogo.size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: _corners,
              boxShadow: AppShadows.medium,
              border: Border.all(color: AppColors.white, width: _frame),
              image: image == null
                  ? null
                  : DecorationImage(image: image, fit: BoxFit.cover),
            ),
          ),
        ),
      ),
    );
  }
}
