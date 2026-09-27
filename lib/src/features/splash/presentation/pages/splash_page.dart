import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/route_args/shell_entrance.dart';
import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../widgets/splash_player.dart';
import '../widgets/splash_variant.dart';

/// The Hero brand splash: the bag on the launch screen comes alive on the
/// brand green, takes off in its cape and delivers the name, then the app
/// fades in ([ShellEntrance.splash]). The intro is [variant] — by default the one this
/// build was made with ([SplashVariant.configured]).
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, this.variant});

  final SplashVariant? variant;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _routed = false;

  void _goToShell() {
    if (_routed || !mounted) return;
    _routed = true;
    context.go(Routes.shell, extra: ShellEntrance.splash);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.primary,
    body: Semantics(
      label: 'app_name'.tr(),
      container: true,
      child: SplashPlayer(
        variant: widget.variant ?? SplashVariant.configured,
        onFinished: _goToShell,
      ),
    ),
  );
}
