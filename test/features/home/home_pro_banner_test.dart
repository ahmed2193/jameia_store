// The Pro slot at the end of the home feed, keyed on the app-global Pro
// status: nothing while the standing is unknown, the offer ("Join Pro") for
// a guest and a non-member, a win-back for a lapsed member ("Rejoin"), the
// member card (perks on, the renewal date) for a member — never "Join" — and
// the end date once cancelled; a subscribe fades through from one to the
// other. The offer's shine loops, so the tests advance fixed frames.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hero_mart/src/core/domain/entities/auth_customer_entity.dart';
import 'package:hero_mart/src/features/home/domain/entities/home_bootstrap.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_pro_banner.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_pro_member_banner.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_pro_offer_banner.dart';
import 'package:hero_mart/src/features/store_mode/domain/entities/pro_membership.dart';
import 'package:hero_mart/src/features/store_mode/presentation/cubit/pro_status_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../store_mode/pro_status_fakes.dart';

const HomeProInfo _pro = HomeProInfo(
  enabled: true,
  freeDelivery: true,
  pointsMultiplier: 2,
  discountPercent: 5,
);

const AuthCustomerEntity _customer = AuthCustomerEntity(
  id: 'c1',
  phone: '+96550001122',
);

ProSubscription _subscription({
  ProSubscriptionStatus status = ProSubscriptionStatus.active,
  bool cancelAtPeriodEnd = false,
}) => ProSubscription(
  id: 's1',
  planId: 'monthly',
  planName: 'Monthly',
  status: status,
  cancelAtPeriodEnd: cancelAtPeriodEnd,
  currentPeriodEnd: DateTime(2026, 10, 17, 12),
);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('en');
  });

  Future<void> frames(WidgetTester tester, [int count = 10]) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> pump(
    WidgetTester tester,
    ProStatusCubit status, {
    VoidCallback? onTap,
  }) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          saveLocale: false,
          child: BlocProvider<ProStatusCubit>.value(
            value: status,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: HomeProBanner(pro: _pro, onTap: onTap ?? () {}),
                ),
              ),
            ),
          ),
        ),
      );
      // Lets the translation asset load for real.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await frames(tester);
  }

  Future<void> teardownApp(WidgetTester tester, ProStatusCubit status) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    // Also drops a member's watch on the end of the paid period.
    await status.close();
  }

  testWidgets('unknown standing: the slot stays empty', (tester) async {
    final status = buildProStatus();
    await pump(tester, status);

    expect(find.byType(HomeProOfferBanner), findsNothing);
    expect(find.byType(HomeProMemberBanner), findsNothing);

    await teardownApp(tester, status);
  });

  testWidgets('guest: the offer, its perks and "Join Pro"; tap opens Pro', (
    tester,
  ) async {
    var taps = 0;
    final status = await settledProStatus();
    await pump(tester, status, onTap: () => taps++);

    expect(find.text('Hero Pro'), findsOneWidget);
    expect(find.text('Join Pro'), findsOneWidget);
    expect(find.text('Free delivery'), findsOneWidget);
    expect(find.text('×2 points'), findsOneWidget);
    expect(find.text('5% off'), findsOneWidget);

    await tester.tap(find.byType(HomeProOfferBanner));
    await frames(tester, 3);
    expect(taps, 1);

    await teardownApp(tester, status);
  });

  testWidgets('lapsed member: come back to Pro, "Rejoin"', (tester) async {
    final status = await settledProStatus(
      customer: _customer,
      subscription: _subscription(status: ProSubscriptionStatus.expired),
    );
    await pump(tester, status);

    expect(find.text('Come back to Hero Pro'), findsOneWidget);
    expect(find.text('Rejoin'), findsOneWidget);
    expect(find.text('Join Pro'), findsNothing);

    await teardownApp(tester, status);
  });

  testWidgets('member: perks on, the renewal date — never an offer', (
    tester,
  ) async {
    final status = await settledProStatus(
      customer: _customer,
      subscription: _subscription(),
    );
    await pump(tester, status);

    expect(find.text("You're a Pro member"), findsOneWidget);
    expect(find.text('Renews on Sat, Oct 17, 2026'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(find.byIcon(HeroIcons.checkCircleFill), findsNWidgets(3));
    expect(find.text('Join Pro'), findsNothing);
    expect(find.byType(HomeProOfferBanner), findsNothing);

    await teardownApp(tester, status);
  });

  testWidgets('cancelled member: the perks end on the date', (tester) async {
    final status = await settledProStatus(
      customer: _customer,
      subscription: _subscription(
        status: ProSubscriptionStatus.cancelled,
        cancelAtPeriodEnd: true,
      ),
    );
    await pump(tester, status);

    expect(
      find.text('Your Pro perks end on Sat, Oct 17, 2026'),
      findsOneWidget,
    );
    expect(find.text("Your membership won't renew."), findsOneWidget);
    expect(find.textContaining('Renews on'), findsNothing);

    await teardownApp(tester, status);
  });

  testWidgets('a subscribe fades through from the offer to the member card', (
    tester,
  ) async {
    final repository = FakeProStatusRepository();
    final status = buildProStatus(repository);
    await status.start(_customer);
    await pump(tester, status);
    expect(find.byType(HomeProOfferBanner), findsOneWidget);

    status.apply(_subscription().membership);
    await frames(tester);

    expect(find.byType(HomeProMemberBanner), findsOneWidget);
    expect(find.byType(HomeProOfferBanner), findsNothing);

    await teardownApp(tester, status);
  });

  testWidgets('Arabic: the member card lays out', (tester) async {
    final status = await settledProStatus(
      customer: _customer,
      subscription: _subscription(),
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('ar'),
          saveLocale: false,
          child: BlocProvider<ProStatusCubit>.value(
            value: status,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: Scaffold(
                  body: HomeProBanner(pro: _pro, onTap: () {}),
                ),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await frames(tester);

    expect(find.text('أنت عضو برو'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await teardownApp(tester, status);
  });
}
