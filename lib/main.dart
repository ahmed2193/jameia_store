import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/config/service_locator.dart';
import 'core/navigation/app_keys.dart';
import 'core/routing/app_router.dart';
import 'core/routing/routes.dart';
import 'core/storage/storage_injection.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/image_cache_tuner.dart';
import 'features/account/account_injection_container.dart';
import 'features/account/presentation/cubit/setting_cubit.dart';
import 'features/address/address_injection_container.dart';
import 'features/auth/auth_injection_container.dart';
import 'features/cart/cart_injection_container.dart';
import 'features/cart/presentation/cubit/cart_cubit.dart';
import 'features/checkout/checkout_injection_container.dart';
import 'features/coupons/coupons_injection_container.dart';
import 'features/discovery/discovery_injection_container.dart';
import 'features/home/home_injection_container.dart';
import 'features/language/language_injection_container.dart';
import 'features/language/presentation/cubit/localization_cubit.dart';
import 'features/language/presentation/cubit/localization_state.dart';
import 'features/marketing/marketing_injection_container.dart';
import 'features/orders/orders_injection_container.dart';
import 'features/product_details/product_details_injection_container.dart';
import 'features/search/search_injection_container.dart';
import 'features/shop/shop_injection_container.dart';
import 'features/store_mode/presentation/cubit/store_mode_cubit.dart';
import 'features/store_mode/store_mode_injection_container.dart';
import 'features/support/support_injection_container.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await setupServiceLocator(); // loads dummy data + DI
  await initCoreStorage(); // shared LocalStorage/SharedPreferences (core-owned)
  await initCartFeature(); // cart clean-arch layers
  await initLanguageFeature(); // language clean-arch layers + LocalStorage restore

  // Feature DI (offline local chains). Fully order-independent — all resolve
  // KeetaRepository (from setupServiceLocator) and the shared LocalStorage
  // (from initCoreStorage above).
  initStoreModeFeature(); // global VIP ⇄ Mart source of truth
  initHomeFeature();
  initShopFeature();
  initProductDetailsFeature();
  initOrdersFeature();
  initAddressFeature();
  initSearchFeature();
  initCheckoutFeature();
  initCouponsFeature();
  initDiscoveryFeature();
  initMarketingFeature();
  initAccountFeature();
  initAuthFeature();
  initSupportFeature();

  // Fire-and-forget: tunes the imageCache budget off a /proc/meminfo read; the
  // first frame is fine on Flutter's default budget, so keep it off the hot path.
  unawaited(ImageCacheTuner.install());

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: const KeetaApp(),
    ),
  );
}

class KeetaApp extends StatefulWidget {
  const KeetaApp({super.key});

  @override
  State<KeetaApp> createState() => _KeetaAppState();
}

class _KeetaAppState extends State<KeetaApp> {
  /// One-shot guard so `initializeLocale` is scheduled only once even as the
  /// tree rebuilds on the first locale application.
  bool _localeInitStarted = false;

  @override
  Widget build(BuildContext context) {
    // Keep locale-aware Formatters in sync with the active locale from the first
    // frame (easy_localization restores the saved locale before this runs).
    Intl.defaultLocale = context.locale.languageCode;
    return MultiBlocProvider(
      providers: [
        BlocProvider<CartCubit>(create: (_) => sl<CartCubit>()),
        BlocProvider<StoreModeCubit>(create: (_) => sl<StoreModeCubit>()),
        BlocProvider<LocalizationCubit>(create: (_) => sl<LocalizationCubit>()),
        BlocProvider<SettingCubit>(create: (_) => SettingCubit()),
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
          return MaterialApp(
            title: 'JameiaMart',
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ThemeMode.light,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            initialRoute: Routes.splash,
            onGenerateRoute: AppRouter.onGenerateRoute,
            builder: (context, child) => MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: child!,
            ),
          );
        },
      ),
    );
  }
}
