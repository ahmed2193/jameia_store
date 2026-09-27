// The host the cart page widget tests share: a CartCubit over the fake
// repository, a guest AuthSessionCubit, and a pump that puts a page (or a
// router) under EasyLocalization with both cubits provided.
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/domain/entities/cart_snapshot.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/add_cart_items_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/adjust_cart_line_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/apply_cart_coupon_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/apply_cart_loyalty_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/clear_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/fetch_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/flush_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/remove_cart_coupon_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/remove_cart_line_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/remove_cart_loyalty_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/reset_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/restore_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/set_cart_express_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/set_cart_line_quantity_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/sync_cart_owner_usecase.dart';
import 'package:jameia_mart/src/features/cart/domain/usecases/watch_cart_usecase.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/store_mode/presentation/cubit/pro_status_cubit.dart';

import '../auth/auth_test_fakes.dart';
import '../store_mode/pro_status_fakes.dart';
import 'fake_cart_repository.dart';

/// A started [CartCubit] with every use case on [repository].
CartCubit buildCartCubit(FakeCartRepository repository) => CartCubit(
  watch: WatchCartUseCase(repository),
  restore: RestoreCartUseCase(repository),
  syncOwner: SyncCartOwnerUseCase(repository),
  fetch: FetchCartUseCase(repository),
  flush: FlushCartUseCase(repository),
  adjustLine: AdjustCartLineUseCase(repository),
  setLineQuantity: SetCartLineQuantityUseCase(repository),
  removeLine: RemoveCartLineUseCase(repository),
  addItems: AddCartItemsUseCase(repository),
  clear: ClearCartUseCase(repository),
  applyCoupon: ApplyCartCouponUseCase(repository),
  removeCoupon: RemoveCartCouponUseCase(repository),
  applyLoyalty: ApplyCartLoyaltyUseCase(repository),
  removeLoyalty: RemoveCartLoyaltyUseCase(repository),
  setExpress: SetCartExpressUseCase(repository),
  reset: ResetCartUseCase(repository),
)..start();

/// A signed-out session: no customer, so no loyalty points.
AuthSessionCubit buildGuestSession() => AuthSessionCubit(
  restoreSession: FakeRestoreSessionUseCase(const Right(null)),
  logout: FakeLogoutUseCase(),
  watchExpiry: FakeWatchSessionExpiryUseCase(),
  getCachedCustomer: FakeGetCachedCustomerUseCase(),
  saveCachedCustomer: FakeSaveCachedCustomerUseCase(),
  clearCachedCustomer: FakeClearCachedCustomerUseCase(),
);

/// Pushes [snapshot], then pumps [home] — or [router] — under
/// EasyLocalization (en + ar, starting in [locale]) with [cart] and
/// [session] provided, and the app-global Pro status: [proStatus], or an
/// idle one (standing unknown — no Pro nudge, no "pro" tag). [builder]
/// wraps the app (a MediaQuery override); [loadDelay] is real time for a
/// translation file not read yet. Bounded pumps only (the page's
/// fade-through from the loader): nothing here may loop, but a settle would
/// hide it.
Future<void> pumpCartHost(
  WidgetTester tester, {
  required FakeCartRepository repository,
  required CartCubit cart,
  required AuthSessionCubit session,
  required CartSnapshot snapshot,
  ProStatusCubit? proStatus,
  Widget? home,
  GoRouter? router,
  Locale locale = const Locale('en'),
  TransitionBuilder? builder,
  Duration loadDelay = Duration.zero,
}) async {
  repository.push(snapshot);
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[Locale('en'), Locale('ar')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: locale,
        saveLocale: false,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>.value(value: cart),
            BlocProvider<AuthSessionCubit>.value(value: session),
            if (proStatus != null)
              BlocProvider<ProStatusCubit>.value(value: proStatus)
            else
              BlocProvider<ProStatusCubit>(create: (_) => buildProStatus()),
          ],
          child: Builder(
            builder: (context) => router != null
                ? MaterialApp.router(
                    routerConfig: router,
                    locale: context.locale,
                    supportedLocales: context.supportedLocales,
                    localizationsDelegates: context.localizationDelegates,
                    builder: builder,
                  )
                : MaterialApp(
                    locale: context.locale,
                    supportedLocales: context.supportedLocales,
                    localizationsDelegates: context.localizationDelegates,
                    builder: builder,
                    home: home,
                  ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(loadDelay);
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Emits [snapshot] from the repository as the projection would, then pumps
/// one frame.
Future<void> emitCartSnapshot(
  WidgetTester tester,
  FakeCartRepository repository,
  CartSnapshot snapshot,
) async {
  await tester.runAsync(() async {
    repository.push(snapshot);
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pump();
}
