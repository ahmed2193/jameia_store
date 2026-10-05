import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'config/di/app_global_cubits.dart';
import 'config/routes/app_router.dart';
import 'config/routes/routes.dart';
import 'config/theme/app_theme.dart';
import 'core/motion/haptics.dart';
import 'core/motion/locale_swap_veil_host.dart';
import 'core/utils/rebuild_descendants.dart';
import 'core/widgets/hero_image.dart';
import 'features/account/presentation/cubit/setting_cubit.dart';
import 'features/account/presentation/cubit/setting_state.dart';
import 'features/address/presentation/cubit/address_book_cubit.dart';
import 'features/assistant/presentation/cubit/assistant_availability_cubit.dart';
import 'features/auth/presentation/cubit/auth_session_cubit.dart';
import 'features/auth/presentation/cubit/auth_session_state.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';
import 'features/connectivity/presentation/cubit/connectivity_cubit.dart';
import 'features/connectivity/presentation/cubit/connectivity_state.dart';
import 'features/connectivity/presentation/widgets/connectivity_banner_host.dart';
import 'features/language/presentation/cubit/localization_cubit.dart';
import 'features/language/presentation/cubit/localization_state.dart';
import 'features/notifications/presentation/cubit/unread_notifications_cubit.dart';
import 'features/store_mode/presentation/cubit/pro_status_cubit.dart';

/// App root: the app-global cubits above a [MaterialApp.router] driven by the
/// single [appRouter] (GoRouter).
class HeroApp extends StatefulWidget {
  const HeroApp({super.key});

  @override
  State<HeroApp> createState() => _HeroAppState();
}

class _HeroAppState extends State<HeroApp> {
  static const String _appTitle = 'Hero';
  static const double _maxTextScaleFactor = 1.3;

  /// One-shot guard so `initializeLocale` is scheduled only once even as the
  /// tree rebuilds on the first locale application.
  bool _localeInitStarted = false;

  /// The splash (or no route parsed yet): the connection banner stays away.
  static bool _isOnSplash() {
    final path = appRouter.routerDelegate.currentConfiguration.uri.path;
    return path.isEmpty || path == Routes.splash;
  }

  /// The stored settings are read at launch, so the vibration mute applies
  /// from the first tap; a listener below follows every later change.
  static SettingCubit _setting() {
    final setting = AppGlobalCubits.setting()..loadPreferences();
    Haptics.enabled = setting.state.hapticsEnabled;
    return setting;
  }

  void _syncAccountLanguage(BuildContext context) {
    final session = context.read<AuthSessionCubit>().state;
    final customer = session.customer;
    // Only the backend's record counts: the device copy shown at launch may
    // predate the last language switch.
    if (!session.isVerified || customer == null) return;
    context.read<LocalizationCubit>().syncIfAccountDiffers(customer.language);
  }

  /// The connection came back: every app-global piece that waits on the
  /// network catches up at once — a handful of requests at most, most of
  /// them only when something failed offline. Screens refresh their own
  /// stale data (`ReconnectRefresh`). Nothing the customer did is replayed:
  /// the cart only sends the taps it already owed.
  void _onReconnected(BuildContext context) {
    unawaited(context.read<CartCubit>().onReconnected());
    unawaited(context.read<AuthSessionCubit>().onReconnected());
    unawaited(context.read<AddressBookCubit>().onReconnected());
    unawaited(context.read<UnreadNotificationsCubit>().onReconnected());
    unawaited(context.read<AssistantAvailabilityCubit>().onReconnected());
    unawaited(context.read<ProStatusCubit>().onReconnected());
    unawaited(context.read<LocalizationCubit>().onReconnected());
    HeroImage.retryAllPendingImages();
  }

  @override
  Widget build(BuildContext context) {
    // Keep locale-aware Formatters in sync with the active locale from the first
    // frame (easy_localization restores the saved locale before this runs).
    Intl.defaultLocale = context.locale.languageCode;
    return MultiBlocProvider(
      providers: [
        BlocProvider<CartCubit>(create: (_) => AppGlobalCubits.cart()),
        BlocProvider<LocalizationCubit>(
          create: (_) => AppGlobalCubits.localization(),
        ),
        BlocProvider<SettingCubit>(create: (_) => _setting()),
        BlocProvider<AuthSessionCubit>(
          create: (_) => AppGlobalCubits.authSession(),
        ),
        BlocProvider<UnreadNotificationsCubit>(
          create: (_) => AppGlobalCubits.unreadNotifications(),
        ),
        BlocProvider<AddressBookCubit>(
          create: (_) => AppGlobalCubits.addressBook(),
        ),
        BlocProvider<AssistantAvailabilityCubit>(
          create: (_) => AppGlobalCubits.assistantAvailability(),
        ),
        BlocProvider<ConnectivityCubit>(
          create: (_) => AppGlobalCubits.connectivity(),
        ),
        BlocProvider<ProStatusCubit>(
          create: (_) => AppGlobalCubits.proStatus(),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          // The customer's vibration choice mutes every haptic in one place.
          BlocListener<SettingCubit, SettingState>(
            listenWhen: (previous, current) =>
                previous.hapticsEnabled != current.hapticsEnabled,
            listener: (_, state) => Haptics.enabled = state.hapticsEnabled,
          ),
          // The saved-address book follows the session: device copy + a sync
          // on sign-in (OTP or launch restore) and whenever the signed-in
          // customer changes; wiped from memory and disk on sign-out / expiry
          // — also when a launch finds the session gone.
          BlocListener<AuthSessionCubit, AuthSessionState>(
            listenWhen: (previous, current) =>
                previous.status != current.status ||
                previous.customer?.id != current.customer?.id,
            listener: (context, state) {
              final addressBook = context.read<AddressBookCubit>();
              switch (state.status) {
                case AuthSessionStatus.signedIn:
                  addressBook.start(customerId: state.customer?.id);
                case AuthSessionStatus.signedOut:
                  addressBook.stop();
                case AuthSessionStatus.unknown:
                  break;
              }
            },
          ),
          // The cart mirror follows the session: a sign-in (OTP or launch
          // restore) fetches the merged server cart and sends the guest's
          // unsent taps; a sign-out wipes the customer's cart from the device;
          // a launch without a session binds the mirror to the guest.
          BlocListener<AuthSessionCubit, AuthSessionState>(
            listenWhen: (previous, current) =>
                previous.status != current.status ||
                previous.customer?.id != current.customer?.id,
            listener: (context, state) {
              final cart = context.read<CartCubit>();
              switch (state.status) {
                case AuthSessionStatus.signedIn:
                  cart.onSignedIn(state.customer?.id ?? '');
                case AuthSessionStatus.signedOut:
                  cart.onSignedOut();
                case AuthSessionStatus.unknown:
                  break;
              }
            },
          ),
          // A language switch: the whole app rebuilds once, in place, so
          // every `.tr()` resolves again — const and offstage widgets too —
          // while every route, tab, scroll and page cubit is kept (the
          // screens whose data comes in the request language read it again
          // themselves). Cart line names arrive resolved for the request
          // language too.
          BlocListener<LocalizationCubit, LocalizationState>(
            listenWhen: (previous, current) =>
                previous.isInitialized &&
                current.isInitialized &&
                previous.locale != current.locale,
            listener: (context, _) {
              rebuildDescendants(context);
              context.read<CartCubit>().onLocaleChanged();
            },
          ),
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
          // Where the customer stands with Pro follows the session: what the
          // customer record says at once, then the subscription (renewing,
          // ending, lapsed) — again whenever the record's membership flips
          // (a subscribe re-reads the session); a guest on sign-out / expiry
          // and at a launch without a session.
          BlocListener<AuthSessionCubit, AuthSessionState>(
            listenWhen: (previous, current) =>
                previous.status != current.status ||
                previous.customer?.id != current.customer?.id ||
                previous.customer?.isPro != current.customer?.isPro,
            listener: (context, state) {
              final pro = context.read<ProStatusCubit>();
              switch (state.status) {
                case AuthSessionStatus.signedIn:
                  pro.start(state.customer);
                case AuthSessionStatus.signedOut:
                  pro.stop();
                case AuthSessionStatus.unknown:
                  break;
              }
            },
          ),
          // The network layer gave up refreshing the session: replace the
          // whole stack with login and let it explain why (`extra: true`).
          // A home read the splash started goes with the session.
          BlocListener<AuthSessionCubit, AuthSessionState>(
            listenWhen: (previous, current) =>
                !previous.expired && current.expired,
            listener: (_, _) {
              AppGlobalCubits.dropHomePrefetch();
              appRouter.go(Routes.login, extra: true);
            },
          ),
          // Mirror the device language onto the account when the profile
          // disagrees. Two triggers, because at launch the session restore and
          // the locale restore race: whichever lands second performs the check
          // (the cubit refuses to sync before its locale is initialized, so the
          // default `en` can never overwrite an Arabic account). The session
          // side fires once the backend confirmed the customer (OTP or the
          // launch `GET /v1/account/me`), never on the device copy.
          BlocListener<AuthSessionCubit, AuthSessionState>(
            listenWhen: (previous, current) =>
                !previous.isVerified &&
                current.isVerified &&
                current.customer != null,
            listener: (context, _) => _syncAccountLanguage(context),
          ),
          // The saved language is on: the splash's home read may start (B1).
          BlocListener<LocalizationCubit, LocalizationState>(
            listenWhen: (previous, current) =>
                !previous.isInitialized && current.isInitialized,
            listener: (context, _) {
              AppGlobalCubits.homeLocaleReady();
              _syncAccountLanguage(context);
            },
          ),
          // The session restore knows whose app this is (a guest, or the
          // customer it restored): the splash's home read may start — the
          // home copy is kept per identity, so a read before this would miss
          // it and leave home on an error when the request fails.
          BlocListener<AuthSessionCubit, AuthSessionState>(
            listenWhen: (previous, current) =>
                previous.status != current.status &&
                current.status != AuthSessionStatus.unknown,
            listener: (_, _) => AppGlobalCubits.homeIdentityReady(),
          ),
          // Once per offline → online recovery (never on raw status flips).
          BlocListener<ConnectivityCubit, ConnectivityState>(
            listenWhen: (previous, current) =>
                previous.reconnectEpoch != current.reconnectEpoch,
            listener: (context, _) => _onReconnected(context),
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
              // The connection banner sits above every route (pages, sheets,
              // dialogs) and pushes them down; never over the splash. The
              // language veil goes over both (docs/motion B3-04).
              builder: (context, child) => MediaQuery.withClampedTextScaling(
                maxScaleFactor: _maxTextScaleFactor,
                child: LocaleSwapVeilHost(
                  child: ConnectivityBannerHost(
                    routeChanges: appRouter.routerDelegate,
                    isOnSplash: _isOnSplash,
                    child: child!,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
