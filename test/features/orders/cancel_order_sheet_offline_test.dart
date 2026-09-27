// Cancelling an order offline: confirming runs a live check first; while the
// connection is still gone the sheet stays open with the reason as chosen and
// says the cancel needs the internet (nothing is sent, nor kept to send
// later); once the check reaches the server the same draft goes out.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/core/domain/entities/order_status.dart';
import 'package:hero_mart/src/core/widgets/app_button.dart';
import 'package:hero_mart/src/core/widgets/connectivity_scope.dart';
import 'package:hero_mart/src/features/orders/domain/entities/cancel_order_request.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/orders_list/cancel_order_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('offline the draft stays; back online the same draft goes', (
    tester,
  ) async {
    var online = false;
    var nudges = 0;
    CancelOrderRequest? sent;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async =>
                    sent = await CancelOrderSheet.show(context, orderId: 'o1'),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          saveLocale: false,
          child: Builder(
            builder: (context) => MaterialApp.router(
              routerConfig: router,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              builder: (context, child) => ConnectivityScope(
                isOffline: true,
                reconnectEpoch: 0,
                onNudge: () => nudges++,
                checkOnline: () async => online,
                child: child!,
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Taking too long'));
    await tester.pumpAndSettle();
    final confirm = find.descendant(
      of: find.byType(CancelOrderSheet),
      matching: find.byType(AppButton),
    );

    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(find.byType(CancelOrderSheet), findsOneWidget);
    expect(
      find.text(
        "You're offline. Your changes are kept, try again when you're back.",
      ),
      findsOneWidget,
    );
    expect(nudges, 1);
    expect(sent, isNull);

    online = true;
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(find.byType(CancelOrderSheet), findsNothing);
    expect(sent?.reason, CancelOrderReason.tooSlow);
    expect(sent?.orderId, 'o1');
  });
}
