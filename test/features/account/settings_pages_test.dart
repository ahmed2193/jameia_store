// Settings, About and Delivery code: the settings data / domain layer and
// SettingCubit over an in-memory LocalStorage, the delivery-code cubit's
// digit handling, and the three pages over the real app-global cubits
// (language switch under the veil, notifications, cache, log out, copy,
// the code editor, RTL digit order).
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jameia_mart/src/config/di/service_locator.dart';
import 'package:jameia_mart/src/config/routes/routes.dart';
import 'package:jameia_mart/src/config/theme/app_theme.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/storage/local_storage.dart';
import 'package:jameia_mart/src/core/usecase/usecase.dart';
import 'package:jameia_mart/src/features/account/data/datasources/settings_local_data_source.dart';
import 'package:jameia_mart/src/features/account/data/repositories/settings_repository_impl.dart';
import 'package:jameia_mart/src/features/account/domain/usecases/clear_app_cache_usecase.dart';
import 'package:jameia_mart/src/features/account/domain/usecases/get_delivery_code_usecase.dart';
import 'package:jameia_mart/src/features/account/domain/usecases/get_notifications_enabled_usecase.dart';
import 'package:jameia_mart/src/features/account/domain/usecases/set_notifications_enabled_usecase.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/delivery_code_cubit.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/setting_cubit.dart';
import 'package:jameia_mart/src/features/account/presentation/pages/mine_about_page.dart';
import 'package:jameia_mart/src/features/account/presentation/pages/mine_delivery_code_page.dart';
import 'package:jameia_mart/src/features/account/presentation/pages/mine_settings_page.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/language/presentation/cubit/localization_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_test_fakes.dart';
import '../../core/network/network_test_fakes.dart';

const AuthCustomerEntity _customer = AuthCustomerEntity(
  id: '507f1f77bcf86cd799439011',
  phone: '+96512345678',
  nameEn: 'Ahmed',
);

/// [LocalStorage] in memory; [failWrites] makes every write report failure.
class _MemoryStorage implements LocalStorage {
  final Map<String, Object> values = {};
  bool failWrites = false;

  @override
  bool? getBool(String key) => values[key] as bool?;

  @override
  String? getString(String key) => values[key] as String?;

  @override
  Future<bool> setBool(String key, {required bool value}) async {
    if (failWrites) return false;
    values[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    if (failWrites) return false;
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async => values.remove(key) != null;
}

class _FakeDeliveryCode implements GetDeliveryCodeUseCase {
  @override
  Future<Either<Failure, String>> call(NoParams params) async =>
      const Right('4821');
}

/// The settings stack over [storage], counting image-cache clean-ups.
class _SettingsStack {
  _SettingsStack(this.storage) {
    final repository = SettingsRepositoryImpl(
      SettingsLocalDataSourceImpl(
        storage,
        clearImageCache: () async => cacheClears++,
      ),
    );
    getEnabled = GetNotificationsEnabledUseCase(repository);
    setEnabled = SetNotificationsEnabledUseCase(repository);
    clearCache = ClearAppCacheUseCase(repository);
  }

  final _MemoryStorage storage;
  int cacheClears = 0;
  late final GetNotificationsEnabledUseCase getEnabled;
  late final SetNotificationsEnabledUseCase setEnabled;
  late final ClearAppCacheUseCase clearCache;

  SettingCubit cubit() => SettingCubit(
    getNotificationsEnabled: getEnabled,
    setNotificationsEnabled: setEnabled,
    clearAppCache: clearCache,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('settings data + domain', () {
    test('notifications start on until the customer turns them off', () async {
      final stack = _SettingsStack(_MemoryStorage());

      expect(
        stack.getEnabled(const NoParams()),
        const Right<Failure, bool>(true),
      );

      await stack.setEnabled(
        const SetNotificationsEnabledParams(enabled: false),
      );

      expect(
        stack.storage.values[SettingsLocalDataSourceImpl.notificationsKey],
        false,
      );
      expect(
        stack.getEnabled(const NoParams()),
        const Right<Failure, bool>(false),
      );
    });

    test(
      'a failed write is a CacheFailure; clearing runs the cleaner',
      () async {
        final stack = _SettingsStack(_MemoryStorage()..failWrites = true);

        final write = await stack.setEnabled(
          const SetNotificationsEnabledParams(enabled: false),
        );
        final clear = await stack.clearCache(const NoParams());

        expect(write.fold((f) => f, (_) => null), isA<CacheFailure>());
        expect(clear, const Right<Failure, Unit>(unit));
        expect(stack.cacheClears, 1);
      },
    );
  });

  group('SettingCubit', () {
    test('loads the stored choice and stores a new one at once', () async {
      final stack = _SettingsStack(
        _MemoryStorage()
          ..values[SettingsLocalDataSourceImpl.notificationsKey] = false,
      );
      final cubit = stack.cubit()..loadPreferences();
      expect(cubit.state.notificationsEnabled, isFalse);

      final write = cubit.setNotificationsEnabled(true);
      // Optimistic: the switch moves before the write lands.
      expect(cubit.state.notificationsEnabled, isTrue);
      await write;

      expect(
        stack.storage.values[SettingsLocalDataSourceImpl.notificationsKey],
        true,
      );
      expect(cubit.state.failure, isNull);
      await cubit.close();
    });

    test('a failed write puts the switch back and reports it', () async {
      final stack = _SettingsStack(_MemoryStorage()..failWrites = true);
      final cubit = stack.cubit()..loadPreferences();

      await cubit.setNotificationsEnabled(false);

      expect(cubit.state.notificationsEnabled, isTrue);
      expect(cubit.state.failure, isA<CacheFailure>());
      await cubit.close();
    });

    test('clearing the cache ignores a second tap while it runs', () async {
      final stack = _SettingsStack(_MemoryStorage());
      final cubit = stack.cubit();

      final first = cubit.clearCache();
      expect(cubit.state.isClearingCache, isTrue);
      await cubit.clearCache();
      await first;

      expect(cubit.state.isClearingCache, isFalse);
      expect(stack.cacheClears, 1);
      await cubit.close();
    });

    test('without injected use cases the choice lives in memory', () async {
      final cubit = SettingCubit()..loadPreferences();

      await cubit.setNotificationsEnabled(false);
      await cubit.clearCache();

      expect(cubit.state.notificationsEnabled, isFalse);
      expect(cubit.state.isClearingCache, isFalse);
      expect(cubit.state.failure, isNull);
      await cubit.close();
    });
  });

  group('DeliveryCodeCubit', () {
    test('keeps four digits of any script, as ASCII', () async {
      final cubit = DeliveryCodeCubit(_FakeDeliveryCode());
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.savedCode, '4821');
      expect(cubit.state.canSave, isFalse);

      cubit.edit('١٢a۳45');

      expect(cubit.state.draft, '1234');
      expect(cubit.state.canSave, isTrue);
      await cubit.close();
    });

    test('saves only a complete, new code', () async {
      final cubit = DeliveryCodeCubit(_FakeDeliveryCode());
      await Future<void>.delayed(Duration.zero);

      cubit
        ..edit('12')
        ..save();
      expect(cubit.state.saved, isFalse);

      cubit
        ..edit('1234')
        ..save();
      expect(cubit.state.savedCode, '1234');
      expect(cubit.state.saved, isTrue);

      cubit.edit('123');
      expect(cubit.state.saved, isFalse);
      await cubit.close();
    });
  });

  group('pages', () {
    late AuthSessionCubit session;
    late FakeLogoutUseCase logout;
    late _SettingsStack stack;
    late SettingCubit settings;
    final List<MethodCall> platformCalls = [];

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      FlutterSecureStorage.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      await initializeDateFormatting('en');
      registerFakeNetworkInfo();
      await setupServiceLocator();
      sl
        ..unregister<DeliveryCodeCubit>()
        ..registerFactory(() => DeliveryCodeCubit(_FakeDeliveryCode()));
    });

    setUp(() {
      logout = FakeLogoutUseCase();
      session = AuthSessionCubit(
        restoreSession: FakeRestoreSessionUseCase(const Right(null)),
        logout: logout,
        watchExpiry: FakeWatchSessionExpiryUseCase(),
        getCachedCustomer: FakeGetCachedCustomerUseCase(),
        saveCachedCustomer: FakeSaveCachedCustomerUseCase(),
        clearCachedCustomer: FakeClearCachedCustomerUseCase(),
      );
      stack = _SettingsStack(_MemoryStorage());
      settings = stack.cubit();
      platformCalls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            platformCalls.add(call);
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Future<void> frames(WidgetTester tester, [int count = 12]) async {
      for (var i = 0; i < count; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    /// Mounts [page] at `/` over the app-global cubits, with stand-ins for
    /// the routes it opens.
    Future<GoRouter> pump(
      WidgetTester tester,
      Widget page, {
      Locale locale = const Locale('en'),
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      Widget stub(String name) => Scaffold(body: Text(name));
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => page),
          GoRoute(path: Routes.login, builder: (_, _) => stub('login-page')),
          GoRoute(path: Routes.mineAbout, builder: (_, _) => stub('about')),
          GoRoute(
            path: Routes.contentPage,
            builder: (_, state) => stub('content ${state.extra}'),
          ),
          GoRoute(
            path: Routes.profileEdit,
            builder: (_, _) => stub('profile-edit'),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('en'), Locale('ar')],
            path: 'assets/i18n',
            fallbackLocale: const Locale('en'),
            startLocale: locale,
            saveLocale: false,
            child: MultiBlocProvider(
              providers: [
                BlocProvider<LocalizationCubit>(
                  create: (_) => sl<LocalizationCubit>(),
                ),
                BlocProvider<SettingCubit>.value(value: settings),
                BlocProvider<AuthSessionCubit>.value(value: session),
              ],
              child: Builder(
                builder: (context) => MaterialApp.router(
                  theme: AppTheme.light,
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  routerConfig: router,
                ),
              ),
            ),
          ),
        );
        // Lets the translation asset load for real.
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await frames(tester);
      return router;
    }

    Future<void> teardown(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      await tester.runAsync(() async {
        await session.close();
        await settings.close();
      });
    }

    testWidgets('settings: grouped rows; signed out there is no log out', (
      tester,
    ) async {
      await pump(tester, const MineSettingsPage());

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('EN'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Account and security'), findsOneWidget);
      expect(find.text('Privacy'), findsOneWidget);
      expect(find.text('Clear cache'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Log out'), findsNothing);
      // No invented cache size any more.
      expect(find.textContaining('MB'), findsNothing);

      await teardown(tester);
    });

    testWidgets('settings: notifications flip and persist; cache clears', (
      tester,
    ) async {
      await pump(tester, const MineSettingsPage());

      expect(settings.state.notificationsEnabled, isTrue);
      await tester.tap(find.text('Notifications'));
      await frames(tester, 3);

      expect(settings.state.notificationsEnabled, isFalse);
      expect(
        stack.storage.values[SettingsLocalDataSourceImpl.notificationsKey],
        false,
      );
      final toggle = tester.widget<Switch>(find.byType(Switch));
      expect(toggle.value, isFalse);

      await tester.tap(find.text('Clear cache'));
      await frames(tester, 3);

      expect(stack.cacheClears, 1);
      expect(find.text('Cache cleared'), findsOneWidget);

      await teardown(tester);
    });

    testWidgets('settings: privacy and about open their pages', (tester) async {
      final router = await pump(tester, const MineSettingsPage());

      await tester.tap(find.text('Privacy'));
      await frames(tester, 5);
      expect(find.text('content privacy'), findsOneWidget);

      router.pop();
      await frames(tester, 5);
      await tester.tap(find.text('About'));
      await frames(tester, 5);
      expect(find.text('about'), findsOneWidget);

      await teardown(tester);
    });

    testWidgets('settings: log out asks, ends the session, lands on login', (
      tester,
    ) async {
      session.signedIn(_customer);
      await pump(tester, const MineSettingsPage());

      await tester.tap(find.text('Log out'));
      await frames(tester, 5);
      expect(find.text('Are you sure you want to log out?'), findsOneWidget);

      // Cancel keeps the session.
      await tester.tap(find.text('Cancel'));
      await frames(tester, 5);
      expect(logout.calls, 0);
      expect(find.text('Are you sure you want to log out?'), findsNothing);

      await tester.tap(find.text('Log out'));
      await frames(tester, 5);
      await tester.tap(find.text('Log out').last);
      await frames(tester, 5);

      expect(logout.calls, 1);
      expect(session.state.isSignedIn, isFalse);
      expect(find.text('login-page'), findsOneWidget);

      await teardown(tester);
    });

    testWidgets('settings: picking العربية switches the app under the veil', (
      tester,
    ) async {
      await pump(tester, const MineSettingsPage());

      await tester.tap(find.text('العربية'));
      // The thumb lands, the veil fades in, the locale loads, the veil fades
      // out: real asset IO interleaved with frames.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 60));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      await frames(tester, 5);

      expect(find.text('الإعدادات'), findsOneWidget);
      expect(find.text('اللغة'), findsOneWidget);
      expect(find.text('Settings'), findsNothing);
      expect(settings.state.isChangingLanguage, isFalse);
      final context = tester.element(find.byType(MineSettingsPage));
      expect(Directionality.of(context), TextDirection.rtl);

      await teardown(tester);
    });

    testWidgets('about: rows, version, a social tile copies its address', (
      tester,
    ) async {
      final router = await pump(tester, const MineAboutPage());

      expect(find.text('About'), findsOneWidget);
      expect(find.text('Version 1.0.0'), findsOneWidget);
      expect(find.text('Terms of service'), findsOneWidget);
      expect(find.text('Privacy policy'), findsOneWidget);
      expect(find.text('Licenses'), findsOneWidget);
      expect(find.text('Rate us'), findsOneWidget);
      expect(find.text('Facebook'), findsOneWidget);
      expect(find.text('Instagram'), findsOneWidget);

      await tester.tap(find.text('Facebook'));
      await frames(tester, 3);

      final copy = platformCalls.lastWhere(
        (call) => call.method == 'Clipboard.setData',
      );
      expect((copy.arguments as Map)['text'], 'facebook.com/Jameia');
      expect(find.text('facebook.com/Jameia copied'), findsOneWidget);

      await tester.tap(find.text('Terms of service'));
      await frames(tester, 5);
      expect(find.text('content terms'), findsOneWidget);
      router.pop();

      await teardown(tester);
    });

    testWidgets('delivery code: copy flips to Copied; a new code saves', (
      tester,
    ) async {
      await pump(tester, const MineDeliveryCodePage());

      for (final digit in ['4', '8', '2', '1']) {
        // The big code and the editor both show it.
        expect(find.text(digit), findsNWidgets(2));
      }

      await tester.tap(find.text('Copy code'));
      await frames(tester, 4);
      expect(find.text('Copied'), findsOneWidget);
      final copy = platformCalls.lastWhere(
        (call) => call.method == 'Clipboard.setData',
      );
      expect((copy.arguments as Map)['text'], '4821');
      // Back to "Copy code" after a moment.
      await frames(tester, 25);
      expect(find.text('Copy code'), findsOneWidget);

      // An Arabic keyboard's digits are stored as ASCII.
      await tester.enterText(find.byType(TextField), '١٢٣٤');
      await frames(tester, 3);
      expect(find.text('1'), findsNWidgets(2));
      expect(find.text('4'), findsNWidgets(1));

      await tester.tap(find.text('Save'));
      await frames(tester, 6);
      expect(find.text('Delivery code updated'), findsOneWidget);
      // The big code flipped to the new digits.
      expect(find.text('4'), findsNWidgets(2));
      expect(find.text('8'), findsNothing);

      await teardown(tester);
    });

    testWidgets('delivery code: digits stay left-to-right in Arabic', (
      tester,
    ) async {
      await pump(
        tester,
        const MineDeliveryCodePage(),
        locale: const Locale('ar'),
      );

      expect(find.text('رمز التسليم'), findsOneWidget);
      final four = tester.getCenter(find.text('4').first);
      final one = tester.getCenter(find.text('1').first);
      expect(four.dx, lessThan(one.dx));

      await teardown(tester);
    });
  });
}
