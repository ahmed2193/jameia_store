import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/di/app_global_cubits.dart';
import 'config/routes/app_router.dart';
import 'config/routes/routes.dart';
import 'config/theme/app_theme.dart';
import 'features/account/presentation/cubit/setting_cubit.dart';
import 'features/auth/presentation/cubit/auth_session_cubit.dart';
import 'features/auth/presentation/cubit/auth_session_state.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';
import 'features/language/presentation/cubit/localization_cubit.dart';
import 'features/language/presentation/cubit/localization_state.dart';
import 'features/notifications/presentation/cubit/unread_notifications_cubit.dart';
import 'features/store_mode/presentation/cubit/store_mode_cubit.dart';

/// App root: the app-global cubits above a [MaterialApp.router] driven by the
/// single [appRouter] (GoRouter).
class JameiaApp extends StatefulWidget {
  const JameiaApp({super.key});

  @override
  State<JameiaApp> createState() => _JameiaAppState();
}

class _JameiaAppState extends State<JameiaApp> {
  static const String _appTitle = 'JameiaMart';
  static const double _maxTextScaleFactor = 1.3;

  /// One-shot guard so `initializeLocale` is scheduled only once even as the
  /// tree rebuilds on the first locale application.
  bool _localeInitStarted = false;

  void _syncAccountLanguage(BuildContext context) {
    final customer = context.read<AuthSessionCubit>().state.customer;
    if (customer == null) return;
    context.read<LocalizationCubit>().syncIfAccountDiffers(customer.language);
  }

  @override
  Widget build(BuildContext context) {
    // Keep locale-aware Formatters in sync with the active locale from the first
    // frame (easy_localization restores the saved locale before this runs).
    Intl.defaultLocale = context.locale.languageCode;
    return MultiBlocProvider(
      providers: [
        BlocProvider<CartCubit>(create: (_) => AppGlobalCubits.cart()),
        BlocProvider<StoreModeCubit>(
          create: (_) => AppGlobalCubits.storeMode(),
        ),
        BlocProvider<LocalizationCubit>(
          create: (_) => AppGlobalCubits.localization(),
        ),
        BlocProvider<SettingCubit>(create: (_) => SettingCubit()),
        BlocProvider<AuthSessionCubit>(
          create: (_) => AppGlobalCubits.authSession(),
        ),
        BlocProvider<UnreadNotificationsCubit>(
          create: (_) => AppGlobalCubits.unreadNotifications(),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          // The unread badge + its live (SSE) stream follow the session:
          // start on sign-in (OTP or launch restore), stop on sign-out / expiry.
          BlocListener<AuthSessionCubit, AuthSessionState>(
            listenWhen: (previous, current) =>
                previous.isSignedIn != current.isSignedIn,
            listener: (context, state) {
              final unread = context.read<UnreadNotificationsCubit>();
              state.isSignedIn ? unread.start() : unread.stop();
            },
          ),
          // The network layer gave up refreshing the session: replace the
          // whole stack with login and let it explain why (`extra: true`).
          BlocListener<AuthSessionCubit, AuthSessionState>(
            listenWhen: (previous, current) =>
                !previous.expired && current.expired,
            listener: (_, _) => appRouter.go(Routes.login, extra: true),
          ),
          // Mirror the device language onto the account when the profile
          // disagrees. Two triggers, because at launch the session restore and
          // the locale restore race: whichever lands second performs the check
          // (the cubit refuses to sync before its locale is initialized, so the
          // default `en` can never overwrite an Arabic account).
          BlocListener<AuthSessionCubit, AuthSessionState>(
            listenWhen: (previous, current) =>
                !previous.isSignedIn &&
                current.isSignedIn &&
                current.customer != null,
            listener: (context, _) => _syncAccountLanguage(context),
          ),
          BlocListener<LocalizationCubit, LocalizationState>(
            listenWhen: (previous, current) =>
                !previous.isInitialized && current.isInitialized,
            listener: (context, _) => _syncAccountLanguage(context),
          ),
        ],
        child: BlocBuilder<LocalizationCubit, LocalizationState>(
          buildWhen: (p, c) =>
              p.locale != c.locale || p.isInitialized != c.isInitialized,
          builder: (context, locState) {
            // Restore the saved language once, after the first frame, from a
            // context that has both EasyLocalization and the cubit as ancestors.
            if (!locState.isInitialized && !_localeInitStarted) {
              _localeInitStarted = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  context.read<LocalizationCubit>().initializeLocale(context);
                }
              });
            }
            return MaterialApp.router(
              title: _appTitle,
              debugShowCheckedModeBanner: false,
              routerConfig: appRouter,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.light,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              builder: (context, child) => MediaQuery.withClampedTextScaling(
                maxScaleFactor: _maxTextScaleFactor,
                child: child!,
              ),
            );
          },
        ),
      ),
    );
  }
}
