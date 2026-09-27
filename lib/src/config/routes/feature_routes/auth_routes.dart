import 'package:go_router/go_router.dart';

import '../../../core/navigation/hero_cross_fade_page.dart';
import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/auth/presentation/pages/otp_verify_page.dart';
import '../route_args/login_args.dart';
import '../route_args/otp_verify_args.dart';
import '../routes.dart';

/// Sign-in: phone entry, then OTP verification — two steps of one flow that
/// share the brand header, so both only cross-fade: the header both pages
/// paint the same stays put while the sheet swaps, and the phone step's sheet
/// rises by itself as the page opens.
final List<RouteBase> authRoutes = <RouteBase>[
  GoRoute(
    path: Routes.login,
    pageBuilder: (_, state) {
      // `extra: true` = opened because the session expired (shows the
      // notice); `LoginArgs` may also name the page to return to.
      final args = LoginArgs.from(state.extra);
      return HeroCrossFadePage<Object?>(
        key: state.pageKey,
        name: state.uri.path,
        child: LoginPage(
          sessionExpired: args.sessionExpired,
          returnTo: args.returnTo,
        ),
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
