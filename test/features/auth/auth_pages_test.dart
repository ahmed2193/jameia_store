// End-to-end widget flow over the real route table: login → OTP → shell,
// with the network replaced by fake use cases behind the real DI container.
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
import 'package:hero_mart/src/features/address/presentation/cubit/address_book_cubit.dart';
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/routes/app_router.dart';
import 'package:hero_mart/src/config/routes/route_args/login_args.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/config/theme/app_theme.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/widgets/hero_submit_button.dart';
import 'package:hero_mart/src/features/account/presentation/cubit/setting_cubit.dart';
import 'package:hero_mart/src/features/assistant/presentation/cubit/assistant_availability_cubit.dart';
import 'package:hero_mart/src/features/auth/domain/entities/phone_number.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/login_cubit.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/otp_cubit.dart';
import 'package:hero_mart/src/features/auth/presentation/widgets/login/login_guest_button.dart';
import 'package:hero_mart/src/features/auth/presentation/pages/otp_verify_page.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/language/presentation/cubit/localization_cubit.dart';
import 'package:hero_mart/src/features/notifications/presentation/cubit/unread_notifications_cubit.dart';
import 'package:hero_mart/src/features/store_mode/presentation/cubit/pro_status_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_test_fakes.dart';
import '../../core/network/network_test_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeSendOtpUseCase sendOtp;
  late FakeVerifyOtpUseCase verifyOtp;
  late FakeWatchSessionExpiryUseCase watchExpiry;
  late AuthSessionCubit session;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    registerFakeNetworkInfo();
    await setupServiceLocator();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  setUp(() {
    sendOtp = FakeSendOtpUseCase(const Right(kChallenge));
    verifyOtp = FakeVerifyOtpUseCase(const Right(kCustomer));
    watchExpiry = FakeWatchSessionExpiryUseCase();
    session = AuthSessionCubit(
      restoreSession: FakeRestoreSessionUseCase(const Right(null)),
      logout: FakeLogoutUseCase(),
      watchExpiry: watchExpiry,
      getCachedCustomer: FakeGetCachedCustomerUseCase(),
      saveCachedCustomer: FakeSaveCachedCustomerUseCase(),
      clearCachedCustomer: FakeClearCachedCustomerUseCase(),
    );
    // Swap the page cubits' network for the fakes; DI shape stays real.
    sl
      ..unregister<LoginCubit>()
      ..registerFactory(() => LoginCubit(sendOtp, FakeGetWelcomeBonusUseCase()))
      ..unregister<OtpCubit>()
      ..registerFactoryParam<OtpCubit, PhoneNumber, String?>(
        (phone, debugCode) => OtpCubit(
          sendOtp: sendOtp,
          verifyOtp: verifyOtp,
          phone: phone,
          debugCode: debugCode,
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
      initialLocation: Routes.login,
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
            BlocProvider<AddressBookCubit>(
              create: (_) => sl<AddressBookCubit>(),
            ),
            BlocProvider<AuthSessionCubit>.value(value: session),
            BlocProvider<UnreadNotificationsCubit>(
              create: (_) => sl<UnreadNotificationsCubit>(),
            ),
            // Sign-in lands on home, whose header reads it. Never loaded:
            // the assistant disc stays hidden and nothing reaches the network.
            BlocProvider<AssistantAvailabilityCubit>(
              create: (_) => sl<AssistantAvailabilityCubit>(),
            ),
            // Home's header and the Pro page read it. Never started: the
            // Pro standing is unknown and nothing reaches the network.
            BlocProvider<ProStatusCubit>(create: (_) => sl<ProStatusCubit>()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      ),
    );
    await settle(tester);
    return router;
  }

  Future<void> teardownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 70));
  }

  Future<GoRouter> reachOtpPage(WidgetTester tester) async {
    final router = await pumpApp(tester);
    await tester.enterText(find.byType(TextField), '12345678');
    await tester.pump();
    await tester.tap(find.byType(HeroSubmitButton));
    await settle(tester);
    expect(router.state.uri.path, Routes.otpVerify);
    expect(find.byType(OtpVerifyPage), findsOneWidget);
    return router;
  }

  testWidgets('valid phone + Continue sends the OTP and opens the OTP page', (
    tester,
  ) async {
    await reachOtpPage(tester);
    expect(sendOtp.calls.single.phone, kPhone);
    expect(find.textContaining('+965 12345678'), findsOneWidget);
    await teardownApp(tester);
  });

  testWidgets('Continue as guest opens the shell without signing in', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    final guest = find.byType(LoginGuestButton);
    await tester.ensureVisible(guest);
    await tester.pump();
    await tester.tap(guest);
    await settle(tester);
    expect(router.state.uri.path, Routes.shell);
    expect(sendOtp.calls, isEmpty);
    await teardownApp(tester);
  });

  testWidgets('send-otp failure shows the localized transport message', (
    tester,
  ) async {
    sendOtp.result = const Left(TimeoutFailure());
    final router = await pumpApp(tester);
    await tester.enterText(find.byType(TextField), '12345678');
    await tester.pump();
    await tester.tap(find.byType(HeroSubmitButton));
    await settle(tester);
    expect(router.state.uri.path, Routes.login);
    expect(find.textContaining('The request timed out'), findsOneWidget);
    await teardownApp(tester);
  });

  testWidgets('send-otp with no connection says so; the number stays typed', (
    tester,
  ) async {
    sendOtp.result = const Left(NetworkFailure());
    final router = await pumpApp(tester);
    await tester.enterText(find.byType(TextField), '12345678');
    await tester.pump();
    await tester.tap(find.byType(HeroSubmitButton));
    await settle(tester);
    expect(router.state.uri.path, Routes.login);
    expect(
      find.text(
        "You're offline. Your changes are kept, try again when you're back.",
      ),
      findsOneWidget,
    );
    expect(find.text('12345678'), findsOneWidget);
    await teardownApp(tester);
  });

  testWidgets('correct code signs the session in and replaces the stack', (
    tester,
  ) async {
    final router = await reachOtpPage(tester);
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    await tester.tap(find.byType(HeroSubmitButton));
    await settle(tester);
    expect(verifyOtp.calls.single.code, '1234');
    expect(session.state.isSignedIn, isTrue);
    expect(session.state.customer, kCustomer);
    expect(router.state.uri.path, Routes.shell);
    await teardownApp(tester);
  });

  testWidgets('signed in from a page that asked for it: back on that page', (
    tester,
  ) async {
    final router = await pumpApp(tester);
    // The Pro page's "Sign in to join".
    router.go(
      Routes.login,
      extra: const LoginArgs(returnTo: Routes.proMembership),
    );
    await settle(tester);
    await tester.enterText(find.byType(TextField), '12345678');
    await tester.pump();
    await tester.tap(find.byType(HeroSubmitButton));
    await settle(tester);
    expect(router.state.uri.path, Routes.otpVerify);

    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    await tester.tap(find.byType(HeroSubmitButton));
    await settle(tester);

    expect(session.state.isSignedIn, isTrue);
    expect(router.state.uri.path, Routes.proMembership);
    // The shell is under it (rebuilt for the new session): back lands home.
    expect(router.canPop(), isTrue);
    router.pop();
    await settle(tester);
    expect(router.state.uri.path, Routes.shell);
    await teardownApp(tester);
  });

  testWidgets('wrong code shows the backend message and stays on the page', (
    tester,
  ) async {
    verifyOtp.result = const Left(
      ServerFailure('Wrong code', statusCode: 400, code: 'INVALID_CREDENTIALS'),
    );
    final router = await reachOtpPage(tester);
    await tester.enterText(find.byType(TextField), '0000');
    await tester.pump();
    await tester.tap(find.byType(HeroSubmitButton));
    await settle(tester);
    expect(find.text('Wrong code'), findsOneWidget);
    expect(router.state.uri.path, Routes.otpVerify);
    expect(session.state.isSignedIn, isFalse);
    await teardownApp(tester);
  });
}
