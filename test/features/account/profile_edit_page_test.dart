// Edit-profile page over the real route table + DI, with the network replaced
// by fake use cases: seeded form, edit, save → session updated + page popped.
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jameia_mart/src/config/di/service_locator.dart';
import 'package:jameia_mart/src/config/routes/app_router.dart';
import 'package:jameia_mart/src/config/routes/routes.dart';
import 'package:jameia_mart/src/config/theme/app_theme.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/profile_cubit.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/setting_cubit.dart';
import 'package:jameia_mart/src/features/account/presentation/pages/profile_edit_page.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/language/presentation/cubit/localization_cubit.dart';
import 'package:jameia_mart/src/features/notifications/presentation/cubit/unread_notifications_cubit.dart';
import 'package:jameia_mart/src/features/store_mode/presentation/cubit/store_mode_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_test_fakes.dart';
import 'account_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGetProfileUseCase getProfile;
  late FakeUpdateProfileUseCase updateProfile;
  late FakeWatchSessionExpiryUseCase watchExpiry;
  late AuthSessionCubit session;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await setupServiceLocator();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  setUp(() {
    getProfile = FakeGetProfileUseCase(const Right(kProfileCustomer));
    updateProfile = FakeUpdateProfileUseCase(const Right(kProfileCustomer));
    watchExpiry = FakeWatchSessionExpiryUseCase();
    session = AuthSessionCubit(
      restoreSession: FakeRestoreSessionUseCase(const Right(kProfileCustomer)),
      logout: FakeLogoutUseCase(),
      watchExpiry: watchExpiry,
    )..signedIn(kProfileCustomer);
    sl
      ..unregister<ProfileCubit>()
      ..registerFactoryParam<ProfileCubit, AuthCustomerEntity?, void>(
        (initial, _) => ProfileCubit(
          getProfile: getProfile,
          updateProfile: updateProfile,
          initial: initial,
        ),
      );
  });

  tearDown(() async {
    await session.close();
    await watchExpiry.controller.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    final router = buildAppRouter(
      initialLocation: Routes.mineAbout,
      rootNavigatorKey: GlobalKey<NavigatorState>(),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        saveLocale: false,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>(create: (_) => sl<CartCubit>()),
            BlocProvider<StoreModeCubit>(create: (_) => sl<StoreModeCubit>()),
            BlocProvider<LocalizationCubit>(
              create: (_) => sl<LocalizationCubit>(),
            ),
            BlocProvider<SettingCubit>(create: (_) => SettingCubit()),
            BlocProvider<AuthSessionCubit>.value(value: session),
            BlocProvider<UnreadNotificationsCubit>(
              create: (_) => sl<UnreadNotificationsCubit>(),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      ),
    );
    await settle(tester);
    router.push(Routes.profileEdit);
    await settle(tester);
    expect(find.byType(ProfileEditPage), findsOneWidget);
    return router;
  }

  Future<void> teardownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 70));
  }

  testWidgets('form is seeded from the session and refreshed from the server', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.widgetWithText(TextField, 'Ahmed'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'ahmed@jm3eia.com'), findsOneWidget);
    expect(getProfile.calls, 1);

    await teardownApp(tester);
  });

  testWidgets(
    'editing the name and saving PATCHes, updates the session, pops',
    (tester) async {
      final router = await pumpApp(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Ahmed'),
        'Ahmed Ali',
      );
      await tester.pump();
      await tester.tap(find.text('Save changes'));
      await settle(tester);

      expect(updateProfile.calls.single.update.name, 'Ahmed Ali');
      expect(session.state.customer, kProfileCustomer);
      expect(router.state.uri.path, Routes.mineAbout);
      expect(find.text('Profile updated'), findsOneWidget);

      await teardownApp(tester);
    },
  );

  testWidgets('a blank name shows the inline error and sends nothing', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Ahmed'), '   ');
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await settle(tester);

    expect(find.text('Name is required'), findsOneWidget);
    expect(updateProfile.calls, isEmpty);
    expect(router.state.uri.path, Routes.profileEdit);

    await teardownApp(tester);
  });

  testWidgets('a backend rejection stays on the page and shows the message', (
    tester,
  ) async {
    updateProfile.result = const Left(
      ServerFailure(
        'Validation failed',
        statusCode: 400,
        code: 'VALIDATION_ERROR',
      ),
    );
    final router = await pumpApp(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Ahmed'),
      'Ahmed Ali',
    );
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await settle(tester);

    expect(find.text('Validation failed'), findsOneWidget);
    expect(router.state.uri.path, Routes.profileEdit);

    await teardownApp(tester);
  });
}
