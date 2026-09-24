// Wallet + loyalty screens over the real route table + DI, with the network
// replaced by fake use cases: balance card, history rows, empty, signed out.
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
import 'package:intl/date_symbol_data_local.dart';
import 'package:jameia_mart/src/config/di/service_locator.dart';
import 'package:jameia_mart/src/config/routes/app_router.dart';
import 'package:jameia_mart/src/config/routes/routes.dart';
import 'package:jameia_mart/src/config/theme/app_theme.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/account/domain/entities/ledger.dart';
import 'package:jameia_mart/src/features/account/domain/entities/loyalty_entry_entity.dart';
import 'package:jameia_mart/src/features/account/domain/entities/loyalty_program.dart';
import 'package:jameia_mart/src/features/account/domain/entities/wallet_entry_entity.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/ledger_cubit.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/loyalty_program_cubit.dart';
import 'package:jameia_mart/src/features/account/presentation/cubit/setting_cubit.dart';
import 'package:jameia_mart/src/features/account/presentation/pages/loyalty_page.dart';
import 'package:jameia_mart/src/features/account/presentation/pages/wallet_page.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/language/presentation/cubit/localization_cubit.dart';
import 'package:jameia_mart/src/features/notifications/presentation/cubit/unread_notifications_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'account_test_fakes.dart';

final Ledger<WalletEntryEntity> _wallet = Ledger<WalletEntryEntity>(
  balance: 2750,
  entries: [
    WalletEntryEntity(
      id: 'w1',
      kind: WalletEntryKind.refund,
      amountFils: 1250,
      createdAt: DateTime(2026, 9, 20, 10),
      note: 'Order #1042',
    ),
    WalletEntryEntity(
      id: 'w2',
      kind: WalletEntryKind.checkout,
      amountFils: -500,
      createdAt: DateTime(2026, 9, 19, 10),
    ),
  ],
  page: 1,
  hasMore: false,
);

final Ledger<LoyaltyEntryEntity> _points = Ledger<LoyaltyEntryEntity>(
  balance: 340,
  entries: [
    LoyaltyEntryEntity(
      id: 'p1',
      kind: LoyaltyEntryKind.earn,
      points: 120,
      createdAt: DateTime(2026, 9, 20, 10),
      expiresAt: DateTime(2027, 9, 20, 10),
    ),
    LoyaltyEntryEntity(
      id: 'p2',
      kind: LoyaltyEntryKind.redeem,
      points: -40,
      createdAt: DateTime(2026, 9, 18, 10),
    ),
  ],
  page: 1,
  hasMore: false,
);

const LoyaltyProgram _program = LoyaltyProgram(
  enabled: true,
  pointsPerKwd: 10,
  redemptionPerPoint: 5,
  minRedeemPoints: 500,
  pointsExpireMonths: 12,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeGetLedgerUseCase<WalletEntryEntity> walletLedger;
  late FakeGetLedgerUseCase<LoyaltyEntryEntity> pointsLedger;

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
    walletLedger = FakeGetLedgerUseCase<WalletEntryEntity>(
      (_) async => Right(_wallet),
    );
    pointsLedger = FakeGetLedgerUseCase<LoyaltyEntryEntity>(
      (_) async => Right(_points),
    );
    sl
      ..unregister<LedgerCubit<WalletEntryEntity>>()
      ..registerFactory<LedgerCubit<WalletEntryEntity>>(
        () => LedgerCubit<WalletEntryEntity>(walletLedger),
      )
      ..unregister<LedgerCubit<LoyaltyEntryEntity>>()
      ..registerFactory<LedgerCubit<LoyaltyEntryEntity>>(
        () => LedgerCubit<LoyaltyEntryEntity>(pointsLedger),
      )
      ..unregister<LoyaltyProgramCubit>()
      ..registerFactory<LoyaltyProgramCubit>(
        () => LoyaltyProgramCubit(
          FakeGetLoyaltyProgramUseCase(const Right(_program)),
        ),
      );
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pumpAt(WidgetTester tester, String path) async {
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
            BlocProvider<AuthSessionCubit>(
              create: (_) => sl<AuthSessionCubit>(),
            ),
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
    router.push(path);
    await settle(tester);
  }

  Future<void> teardownApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  group('WalletPage', () {
    testWidgets('balance card + signed transactions', (tester) async {
      await pumpAt(tester, Routes.wallet);

      expect(find.byType(WalletPage), findsOneWidget);
      expect(find.text('KD 2.750'), findsOneWidget);
      expect(find.text('Transactions'), findsOneWidget);
      expect(find.text('Refund'), findsOneWidget);
      expect(find.text('Order #1042'), findsOneWidget);
      expect(find.text('+KD 1.250'), findsOneWidget);
      expect(find.text('Used at checkout'), findsOneWidget);
      expect(find.text('−KD 0.500'), findsOneWidget);
      expect(walletLedger.calls.single.page, 1);

      await teardownApp(tester);
    });

    testWidgets('no transactions yet → the empty message under the balance', (
      tester,
    ) async {
      walletLedger.handler = (_) async => const Right(
        Ledger<WalletEntryEntity>(
          balance: 0,
          entries: [],
          page: 1,
          hasMore: false,
        ),
      );
      await pumpAt(tester, Routes.wallet);

      expect(find.text('KD 0.000'), findsOneWidget);
      expect(find.text('No wallet activity yet'), findsOneWidget);

      await teardownApp(tester);
    });

    testWidgets('401 → the sign-in prompt', (tester) async {
      walletLedger.handler = (_) async => const Left(UnauthorizedFailure());
      await pumpAt(tester, Routes.wallet);

      expect(find.text('Sign in to see your wallet'), findsOneWidget);
      expect(find.text('Log in or sign up'), findsOneWidget);

      await teardownApp(tester);
    });

    testWidgets('offline → the error view with a retry that reloads', (
      tester,
    ) async {
      walletLedger.handler = (_) async => const Left(NetworkFailure());
      await pumpAt(tester, Routes.wallet);
      expect(find.text('Retry'), findsOneWidget);

      walletLedger.handler = (_) async => Right(_wallet);
      await tester.tap(find.text('Retry'));
      await settle(tester);

      expect(find.text('Refund'), findsOneWidget);
      expect(walletLedger.calls, hasLength(2));

      await teardownApp(tester);
    });
  });

  group('LoyaltyPage', () {
    testWidgets('points, their worth, the rules and the history', (
      tester,
    ) async {
      await pumpAt(tester, Routes.loyalty);

      expect(find.byType(LoyaltyPage), findsOneWidget);
      expect(find.text('340 pts'), findsOneWidget);
      expect(find.text('Worth KD 1.700'), findsOneWidget);
      expect(find.text('How it works'), findsOneWidget);
      expect(
        find.text('Earn 10 points for every KWD 1 you spend'),
        findsOneWidget,
      );
      expect(find.text('1 point = KD 0.005 off'), findsOneWidget);
      expect(find.text('Redeem from 500 points'), findsOneWidget);
      expect(find.text('Points expire after 12 months'), findsOneWidget);

      await tester.ensureVisible(find.text('Points redeemed'));
      expect(find.text('Points earned'), findsOneWidget);
      expect(find.text('+120 pts'), findsOneWidget);
      expect(find.text('Expires Sep 20, 2027'), findsOneWidget);
      expect(find.text('−40 pts'), findsOneWidget);

      await teardownApp(tester);
    });

    testWidgets('without a programme only the balance and history show', (
      tester,
    ) async {
      sl
        ..unregister<LoyaltyProgramCubit>()
        ..registerFactory<LoyaltyProgramCubit>(
          () => LoyaltyProgramCubit(
            FakeGetLoyaltyProgramUseCase(const Left(NetworkFailure())),
          ),
        );
      await pumpAt(tester, Routes.loyalty);

      expect(find.text('340 pts'), findsOneWidget);
      expect(find.textContaining('Worth'), findsNothing);
      expect(find.text('How it works'), findsNothing);
      expect(find.text('Points earned'), findsOneWidget);

      await teardownApp(tester);
    });
  });
}
