import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/routes.dart';
import '../../../../config/theme/app_colors.dart';
import '../widgets/splash_player.dart';

/// Jameia-style brand splash: full yellow with the branded Lottie + Ken-Burns
/// settle, then routes to the main shell once the motion finishes. (Dummy data
/// is already loaded in setupServiceLocator.)
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _routed = false;

  /// Navigation is now driven by [SplashPlayer] finishing instead of a hard
  /// delay; guard so the replacement push only ever fires once.
  void _goToShell() {
    if (_routed || !mounted) return;
    _routed = true;
    context.go(Routes.shell);
  }

  @override
  Widget build(BuildContext context) {
    // Dark status-bar icons over the white splash (runbook §3.5).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SplashPlayer(onFinished: _goToShell),
      ),
    );
  }
}
