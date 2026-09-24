// The product page's buy bar. It lives in the Scaffold's bottomNavigationBar
// slot, which offers the whole screen as its height budget: everything in it
// must size itself from its content, never from the room it is offered.
import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/config/di/service_locator.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/widgets/paging_dots.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/core/error/failures.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/product_details/domain/entities/product_detail.dart';
import 'package:jameia_mart/src/features/product_details/domain/usecases/get_product_detail_usecase.dart';
import 'package:jameia_mart/src/features/product_details/presentation/cubit/product_detail_cubit.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_bottom_bar.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_back_button.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_cart_action.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_quantity_stepper.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_scaffold_view.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_section_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_test_fakes.dart';

const CatalogProductEntity _card = CatalogProductEntity(
  id: 'milk',
  slug: 'milk',
  name: 'Milk 1L',
  priceFils: 499,
  stock: 10,
);
const ProductDetail _detail = ProductDetail(product: _card);

class _StubGetDetail implements GetProductDetailUseCase {
  @override
  Future<Either<Failure, ProductDetail>> call(
    GetProductDetailParams params,
  ) async => const Right(_detail);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await setupServiceLocator();
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  testWidgets('the buy bar is as tall as its contents, not as the screen', (
    tester,
  ) async {
    final detail = ProductDetailCubit(_StubGetDetail(), slug: 'milk')..load();
    addTearDown(detail.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProductDetailCubit>.value(value: detail),
          BlocProvider<AuthSessionCubit>(
            create: (_) => AuthSessionCubit(
              restoreSession: FakeRestoreSessionUseCase(const Right(null)),
              logout: FakeLogoutUseCase(),
              watchExpiry: FakeWatchSessionExpiryUseCase(),
              getCachedCustomer: FakeGetCachedCustomerUseCase(),
              saveCachedCustomer: FakeSaveCachedCustomerUseCase(),
              clearCachedCustomer: FakeClearCachedCustomerUseCase(),
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(),
            bottomNavigationBar: PdpBottomBar(),
          ),
        ),
      ),
    );
    await tester.pump();

    final screen = tester.getSize(find.byType(Scaffold));
    final bar = tester.getSize(find.byType(PdpBottomBar));
    final stepper = tester.getSize(find.byType(PdpQuantityStepper));

    expect(bar.height, lessThan(screen.height / 2));
    expect(
      stepper.height,
      lessThan(screen.height / 2),
      reason: 'a Container with an alignment grows to fill loose constraints',
    );
    expect(find.byType(PdpQuantityStepper), findsOneWidget);
  });

  testWidgets('the photo sheet carries the storefront chrome', (tester) async {
    final detail = ProductDetailCubit(_StubGetDetail(), slug: 'milk')..load();
    addTearDown(detail.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProductDetailCubit>.value(value: detail),
          BlocProvider<CartCubit>(create: (_) => sl<CartCubit>()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PdpScaffoldView(
              images: ['a.jpg', 'b.jpg', 'c.jpg'],
              sections: [PdpSectionCard(child: Text('body'))],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Disc chrome floating on the photo, not a bare arrow on a white strip.
    expect(find.byType(PdpBackButton), findsOneWidget);
    expect(find.byType(PdpCartAction), findsOneWidget);
    // The gallery pages with the app's own dots.
    expect(tester.widget<PagingDots>(find.byType(PagingDots)).count, 3);
    // The blocks are inset cards, like every block on home.
    final card = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(PdpSectionCard),
            matching: find.byType(Container),
          )
          .first,
    );
    expect((card.decoration! as BoxDecoration).borderRadius, isNotNull);
    expect(card.margin, isNotNull);
  });
}
