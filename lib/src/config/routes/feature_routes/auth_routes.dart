import 'package:go_router/go_router.dart';

import '../../../core/navigation/navigation.dart';
import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/auth/presentation/pages/otp_verify_page.dart';
import '../route_args/login_args.dart';
import '../route_args/otp_verify_args.dart';
import '../routes.dart';

/// Sign-in: phone entry, then OTP verification. The phone step is a new root
/// (sign-out and session expiry `go` to it), so it fades through; the code
/// step shares its brand header, so it only cross-fades: the header both
/// pages paint the same stays put while the sheet swaps.
final List<RouteBase> authRoutes = <RouteBase>[
  GoRoute(
    path: Routes.login,
    pageBuilder: (_, state) {
      // `extra: true` = opened because the session expired (shows the
      // notice); `LoginArgs` may also name the page to return to.
      final args = LoginArgs.from(state.extra);
      return HeroFadeThroughPage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: LoginPage(args: args),
      );
    },
  ),
  GoRoute(
    path: Routes.otpVerify,
    pageBuilder: (_, state) {
      final args = state.extra;
      return HeroCrossFadePage<Object?>(
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
