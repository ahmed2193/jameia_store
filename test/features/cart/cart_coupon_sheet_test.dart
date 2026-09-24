// A refused coupon must say so inside the sheet: a snack bar from the page
// below comes up UNDER the modal sheet, so the customer saw nothing happen.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
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
import 'package:jameia_mart/src/features/cart/presentation/widgets/cart/cart_coupon_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_cart_repository.dart';

void main() {
  late FakeCartRepository repository;
  late CartCubit cubit;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    repository = FakeCartRepository();
    cubit = CartCubit(
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
    );
  });

  tearDown(() async {
    await cubit.close();
    await repository.dispose();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const <Locale>[Locale('en')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          child: BlocProvider<CartCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) => MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: const Scaffold(body: CartCouponSheet()),
              ),
            ),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pumpAndSettle();
  }

  testWidgets('a refused code is shown in the sheet', (tester) async {
    await pump(tester);
    repository.failure = const ServerFailure(
      'This coupon is not valid',
      statusCode: 400,
      code: 'COUPON_INVALID',
    );

    await tester.enterText(find.byType(TextField), 'NOPE99');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.text('This coupon is not valid'), findsOneWidget);
  });

  testWidgets('a code the API would refuse for its length never goes out', (
    tester,
  ) async {
    await pump(tester);

    await tester.enterText(find.byType(TextField), 'x');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(repository.calls, isEmpty);
    expect(find.byType(TextField), findsOneWidget); // the sheet stayed open
  });
}
