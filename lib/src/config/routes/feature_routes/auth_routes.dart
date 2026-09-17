import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/auth/presentation/pages/otp_verify_page.dart';
import '../route_args/otp_verify_args.dart';
import '../routes.dart';

/// Sign-in: phone entry, then OTP verification.
final List<RouteBase> authRoutes = <RouteBase>[
  GoRoute(
    path: Routes.login,
    pageBuilder: (_, state) => JameiaTransitionPage<Object?>(
      key: state.pageKey,
      name: state.uri.path,
      // `extra: true` = opened because the session expired (shows the notice).
      child: LoginPage(sessionExpired: state.extra == true),
    ),
  ),
  GoRoute(
    path: Routes.otpVerify,
    pageBuilder: (_, state) {
      final args = state.extra;
      return JameiaTransitionPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        // No phone to verify against → back to the phone step.
        child: args is OtpVerifyArgs
            ? OtpVerifyPage(args: args)
            : const LoginPage(),
      );
    },
  ),
];
