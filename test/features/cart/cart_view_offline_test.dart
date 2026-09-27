// The cart's failures while offline: its own sync retrying in the background
// says nothing (the banner and the "not synced" line already do); a coupon
// the customer applies says it needs the internet and nudges the banner.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/core/widgets/connectivity_scope.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/cart/presentation/widgets/cart/cart_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cart_page_harness.dart';
import 'fake_cart_repository.dart';

void main() {
  late FakeCartRepository repository;
  late CartCubit cart;
  late AuthSessionCubit session;
  late int nudges;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    nudges = 0;
    repository = FakeCartRepository();
    cart = buildCartCubit(repository);
    session = buildGuestSession();
  });

  tearDown(() async {
    await cart.close();
    await session.close();
    await repository.dispose();
  });

  Future<void> pumpOffline(WidgetTester tester) => pumpCartHost(
    tester,
    repository: repository,
    cart: cart,
    session: session,
    snapshot: const CartSnapshot(isRestored: true),
    home: Scaffold(body: CartView(onBrowse: () {})),
    builder: (context, child) => ConnectivityScope(
      isOffline: true,
      reconnectEpoch: 0,
      onNudge: () => nudges++,
      child: child!,
    ),
  );

  testWidgets("offline, the cart's own sync failing says nothing", (
    tester,
  ) async {
    await pumpOffline(tester);

    await emitCartSnapshot(
      tester,
      repository,
      const CartSnapshot(
        isRestored: true,
        hasPendingChanges: true,
        isUnsynced: true,
        failure: NetworkFailure(),
        failedAction: CartAction.sync,
      ),
    );
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
    expect(nudges, 0);
  });

  testWidgets('offline, a coupon says it needs the internet', (tester) async {
    await pumpOffline(tester);

    repository.failure = const NetworkFailure();
    await tester.runAsync(() => cart.applyCoupon('SAVE'));
    await tester.pump();

    expect(
      find.text(
        "You're offline. Your changes are kept, try again when you're back.",
      ),
      findsOneWidget,
    );
    expect(nudges, 1);
  });
}
