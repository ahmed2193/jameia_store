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
import 'package:intl/date_symbol_data_local.dart';
import 'package:jameia_mart/src/config/di/service_locator.dart';
import 'package:jameia_mart/src/config/routes/app_router.dart';
import 'package:jameia_mart/src/config/routes/routes.dart';
import 'package:jameia_mart/src/config/theme/app_theme.dart';
import 'package:jameia_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/account/domain/entities/loyalty_program.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/loyalty_program_cubit.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/profile_cubit.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/setting_cubit.dart';
import 'package:jameia_mart/src/features/account/presentation/pages/profile_edit_page.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/language/presentation/cubit/localization_cubit.dart';
import 'package:jameia_mart/src/features/notifications/presentation/cubit/unread_notifications_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_test_fakes.dart';
import 'account_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGetProfileUseCase getProfile;
  late FakeUpdateProfileUseCase updateProfile;
  late FakeWatchSessionExpiryUseCase watchExpiry;
  late AuthSessionCubit session;

  AuthSessionCubit signedInSession(AuthCustomerEntity customer) =>
      AuthSessionCubit(
        restoreSession: FakeRestoreSessionUseCase(Right(customer)),
        logout: FakeLogoutUseCase(),
        watchExpiry: watchExpiry,
        getCachedCustomer: FakeGetCachedCustomerUseCase(),
        saveCachedCustomer: FakeSaveCachedCustomerUseCase(),
        clearCachedCustomer: FakeClearCachedCustomerUseCase(),
      )..signedIn(customer);

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    // What the Material localizations load in the app: the date symbols.
    await initializeDateFormatting('en');
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
    session = signedInSession(kProfileCustomer);
    sl
      // The profile-bonus hint, without the `/v1/init` request.
      ..unregister<LoyaltyProgramCubit>()
      ..registerFactory<LoyaltyProgramCubit>(
        () => LoyaltyProgramCubit(
          FakeGetLoyaltyProgramUseCase(
            const Right(LoyaltyProgram(enabled: true, profileBonusPoints: 50)),
          ),
        ),
      )
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
    // A tall phone: the whole screen is built and on screen.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
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

  /// The save button sits below the "About you" card: bring it on screen.
  Future<void> tapSave(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await settle(tester);
  }

  /// Swaps the setUp session for [next]. Runs outside the fake-async zone:
  /// the setUp cubit's streams live in the real one, so closing it from the
  /// test body would never complete.
  Future<void> replaceSession(
    WidgetTester tester,
    AuthSessionCubit Function() next,
  ) => tester.runAsync(() async {
    await session.close();
    session = next();
  });

  testWidgets('a session the server confirmed seeds the form with no GET /me', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.widgetWithText(TextField, 'Ahmed'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'ahmed@jm3eia.com'), findsOneWidget);
    expect(getProfile.calls, 0);

    await teardownApp(tester);
  });

  testWidgets('the device copy (not confirmed yet) is refreshed on open', (
    tester,
  ) async {
    await replaceSession(
      tester,
      () => AuthSessionCubit(
        restoreSession: FakeRestoreSessionUseCase(const Left(NetworkFailure())),
        logout: FakeLogoutUseCase(),
        watchExpiry: watchExpiry,
        getCachedCustomer: FakeGetCachedCustomerUseCase(
          const Right(kProfileCustomer),
        ),
        saveCachedCustomer: FakeSaveCachedCustomerUseCase(),
        clearCachedCustomer: FakeClearCachedCustomerUseCase(),
      ),
    );
    // Offline start: signed in from the device copy, not confirmed.
    await tester.runAsync(session.restore);
    expect(session.state.isSignedIn, isTrue);
    expect(session.state.isVerified, isFalse);

    await pumpApp(tester);

    expect(find.widgetWithText(TextField, 'Ahmed'), findsOneWidget);
    expect(getProfile.calls, 1);

    await teardownApp(tester);
  });

  testWidgets('shows the About-you fields and the profile-bonus hint', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('About you'), findsOneWidget);
    expect(find.text('Date of birth'), findsOneWidget);
    expect(find.text('Select a date'), findsOneWidget);
    expect(find.text('Household size'), findsOneWidget);
    expect(find.text('Number of people'), findsOneWidget);
    expect(find.text('Earn 50 points when you fill this in'), findsOneWidget);
    expect(find.text('Complete your profile'), findsNothing);

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
      await tapSave(tester);

      expect(updateProfile.calls.single.update.name, 'Ahmed Ali');
      expect(session.state.customer, kProfileCustomer);
      expect(router.state.uri.path, Routes.mineAbout);
      expect(find.text('Profile updated'), findsOneWidget);

      await teardownApp(tester);
    },
  );

  testWidgets('completing the details announces the points it earned', (
    tester,
  ) async {
    final withBirthday = AuthCustomerEntity(
      id: kProfileCustomer.id,
      phone: kProfileCustomer.phone,
      nameEn: kProfileCustomer.nameEn,
      nameAr: kProfileCustomer.nameAr,
      email: kProfileCustomer.email,
      gender: CustomerGender.male,
      dateOfBirth: DateTime(1990, 5, 17),
      loyaltyPoints: 100,
    );
    final completed = AuthCustomerEntity(
      id: withBirthday.id,
      phone: withBirthday.phone,
      nameEn: withBirthday.nameEn,
      nameAr: withBirthday.nameAr,
      email: withBirthday.email,
      gender: withBirthday.gender,
      dateOfBirth: withBirthday.dateOfBirth,
      householdSize: 1,
      loyaltyPoints: 150,
    );
    await replaceSession(tester, () => signedInSession(withBirthday));
    updateProfile.result = Right(completed);
    await pumpApp(tester);
    expect(find.text('May 17, 1990'), findsOneWidget);

    await tester.ensureVisible(find.byIcon(Icons.add_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    await tapSave(tester);

    expect(updateProfile.calls.single.update.householdSize, 1);
    expect(session.state.customer, completed);
    expect(find.text('Profile updated — you earned 50 points'), findsOneWidget);

    await teardownApp(tester);
  });

  testWidgets('"Clear" removes the date of birth (sent as null)', (
    tester,
  ) async {
    await replaceSession(
      tester,
      () => signedInSession(
        AuthCustomerEntity(
          id: kProfileCustomer.id,
          phone: kProfileCustomer.phone,
          nameEn: kProfileCustomer.nameEn,
          nameAr: kProfileCustomer.nameAr,
          email: kProfileCustomer.email,
          gender: CustomerGender.male,
          dateOfBirth: DateTime(1990, 5, 17),
        ),
      ),
    );
    await pumpApp(tester);

    await tester.tap(find.text('Clear'));
    await tester.pump();
    expect(find.text('Select a date'), findsOneWidget);
    await tapSave(tester);

    expect(updateProfile.calls.single.update.clearDateOfBirth, isTrue);

    await teardownApp(tester);
  });

  testWidgets('the sign-up placeholder name asks to complete the profile', (
    tester,
  ) async {
    await replaceSession(
      tester,
      () => signedInSession(
        const AuthCustomerEntity(
          id: 'n',
          phone: '+96512345678',
          nameEn: '+96512345678',
          nameAr: '+96512345678',
        ),
      ),
    );
    await pumpApp(tester);

    expect(find.text('Complete your profile'), findsOneWidget);
    // The phone number is never offered as the name.
    expect(find.widgetWithText(TextField, '+96512345678'), findsNothing);

    await teardownApp(tester);
  });

  testWidgets('a blank name shows the inline error and sends nothing', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    await tester.enterText(find.widgetWithText(TextField, 'Ahmed'), '   ');
    await tester.pump();
    await tapSave(tester);

    await tester.ensureVisible(find.text('Name is required'));
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
    await tapSave(tester);

    expect(find.text('Validation failed'), findsOneWidget);
    expect(router.state.uri.path, Routes.profileEdit);

    await teardownApp(tester);
  });
}
