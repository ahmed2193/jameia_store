// The product page's chrome. The buy bar lives in the Scaffold's
// bottomNavigationBar slot, which offers the whole screen as its height
// budget: everything in it must size itself from its content, never from the
// room it is offered. The full-bleed grey gallery carries only the round
// back and cart buttons, a white sheet with rounded top corners rides over
// its bottom edge, and the blocks under it are flat, set apart by inset
// hairlines.
import 'dart:convert';

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
import 'package:jameia_mart/src/config/di/service_locator.dart';
import 'package:jameia_mart/src/config/theme/app_colors.dart';
import 'package:jameia_mart/src/config/theme/app_spacing.dart';
import 'package:jameia_mart/src/core/domain/entities/catalog_product_entity.dart';
import 'package:jameia_mart/src/core/widgets/round_outlined_button.dart';
import 'package:jameia_mart/src/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:jameia_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:jameia_mart/src/features/product_details/domain/entities/product_detail.dart';
import 'package:jameia_mart/src/features/product_details/presentation/cubit/product_detail_cubit.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_back_button.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_bottom_bar.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_cart_action.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_cart_cta.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_cta_stepper.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_dots_pill.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_gallery.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_scaffold_view.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_section.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_section_divider.dart';
import 'package:jameia_mart/src/features/product_details/presentation/widgets/pdp_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pdp_test_fakes.dart';

const CatalogProductEntity _card = CatalogProductEntity(
  id: 'milk',
  slug: 'milk',
  name: 'Milk 1L',
  priceFils: 499,
  stock: 10,
);
const ProductDetail _detail = ProductDetail(product: _card);

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
      translations: Translations(
        withNewProductKeys(json.decode(enRaw) as Map<String, dynamic>, 'en'),
      ),
    );
  });

  testWidgets('the buy bar is as tall as its contents, not as the screen', (
    tester,
  ) async {
    final detail = ProductDetailCubit(
      const StubGetDetail(_detail),
      const StubGetOffer(),
      slug: 'milk',
    )..load();
    addTearDown(detail.close);
    // In the basket already: the pill is the stepper of that line.
    final cart = FakeCartCubit.holding(_card, 2);
    addTearDown(cart.close);
    final session = signedOutSession();
    addTearDown(session.close);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ProductDetailCubit>.value(value: detail),
          BlocProvider<AuthSessionCubit>.value(value: session),
          BlocProvider<CartCubit>.value(value: cart),
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
    final pill = tester.getSize(find.byType(PdpCartCta));

    expect(bar.height, lessThan(screen.height / 2));
    expect(
      pill.height,
      PdpCartCta.height,
      reason: 'a Container with an alignment grows to fill loose constraints',
    );
    expect(find.byType(PdpCtaStepper), findsOneWidget);
    expect(
      tester.getSize(find.byType(PdpCtaStepper)).height,
      lessThan(screen.height / 2),
    );
    // A soft shadow above the bar, not a hairline.
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(PdpBottomBar),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(decoration.boxShadow, isNotEmpty);
    expect(decoration.border, isNull);
  });

  testWidgets('the gallery carries only back and cart, under a rounded sheet', (
    tester,
  ) async {
    final detail = ProductDetailCubit(
      const StubGetDetail(_detail),
      const StubGetOffer(),
      slug: 'milk',
    )..load();
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
              title: 'Milk 1L',
              images: ['a.jpg', 'b.jpg', 'c.jpg'],
              sections: [
                PdpSection(child: Text('body')),
                PdpSectionDivider(),
                PdpSection(child: Text('more')),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final screen = tester.getSize(find.byType(Scaffold));
    // Round white chrome on the photo: back and the cart, no search.
    expect(find.byType(PdpBackButton), findsOneWidget);
    expect(find.byType(PdpCartAction), findsOneWidget);
    expect(find.byType(RoundOutlinedButton), findsNWidgets(2));
    expect(find.byIcon(Icons.search_rounded), findsNothing);
    // The gallery pages with its dots pill.
    expect(tester.widget<PdpDotsPill>(find.byType(PdpDotsPill)).count, 3);
    // Full bleed from the very top, on light grey.
    final gallery = tester.getRect(find.byType(PdpGallery));
    expect(gallery.top, 0);
    expect(gallery.left, 0);
    expect(gallery.width, screen.width);
    expect(
      tester
          .widget<ColoredBox>(
            find
                .descendant(
                  of: find.byType(PdpGallery),
                  matching: find.byType(ColoredBox),
                )
                .first,
          )
          .color,
      AppColors.smallBackground,
    );
    // The white sheet reaches into the gallery's grey with rounded top
    // corners: the pager's box stops where it begins, and the grey carries
    // on behind the corners, down to the gallery's full height.
    final sheet = tester.getRect(find.byType(PdpSheet));
    expect(sheet.top, gallery.bottom);
    expect(sheet.width, screen.width);
    expect(
      gallery.height + PdpSheet.overlap,
      PdpScaffoldView.galleryHeight(tester.element(find.byType(PdpGallery))),
    );
    final behindCorners = find.descendant(
      of: find.byType(PdpSheet),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox && widget.color == AppColors.smallBackground,
      ),
    );
    expect(behindCorners, findsOneWidget);
    expect(
      tester.getRect(behindCorners),
      Rect.fromLTWH(0, sheet.top, screen.width, PdpSheet.overlap),
    );
    final sheetDecoration =
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(PdpSheet),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;
    expect(sheetDecoration.color, AppColors.white);
    expect(
      sheetDecoration.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(PdpSheet.radius)),
    );
    // The first block is measured from the sheet's very edge (its own 16 dp
    // padding), not from under a blank strip.
    expect(tester.getTopLeft(find.text('body')).dy, sheet.top + AppSpacing.s16);
    // Dark status bar icons over the light gallery.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is AnnotatedRegion<SystemUiOverlayStyle> &&
            widget.value == SystemUiOverlayStyle.dark,
      ),
      findsWidgets,
    );
    // The blocks are flat and edge to edge: no rounded card, no inset.
    final sections = find.byType(PdpSection);
    expect(sections, findsNWidgets(2));
    for (final section in tester.elementList(sections)) {
      expect(section.size!.width, screen.width);
    }
    final floating = find.descendant(
      of: sections,
      matching: find.byWidgetPredicate(
        (widget) =>
            (widget is Container &&
                (widget.margin != null ||
                    (widget.decoration is BoxDecoration &&
                        (widget.decoration! as BoxDecoration).borderRadius !=
                            null))) ||
            (widget is DecoratedBox &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).borderRadius != null),
      ),
    );
    expect(floating, findsNothing);
    // They are set apart by a hairline inset to the gutters, not a band.
    final line = tester.getRect(
      find.descendant(
        of: find.byType(PdpSectionDivider),
        matching: find.byType(Divider),
      ),
    );
    expect(line.left, PdpSectionDivider.inset);
    expect(line.width, screen.width - PdpSectionDivider.inset * 2);
    expect(line.height, 1);
    expect(
      tester.getSize(find.byType(PdpSectionDivider)).height,
      1 + PdpSectionDivider.gap * 2,
    );
  });

  testWidgets('the cart button wears a brand-green count badge', (
    tester,
  ) async {
    final cart = FakeCartCubit.holding(_card, 3);
    addTearDown(cart.close);

    await tester.pumpWidget(
      BlocProvider<CartCubit>.value(
        value: cart,
        child: const MaterialApp(
          home: Scaffold(body: Center(child: PdpCartAction())),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
    final badge = tester.widget<Container>(
      find.ancestor(of: find.text('3'), matching: find.byType(Container)).first,
    );
    expect((badge.decoration! as BoxDecoration).color, AppColors.primary);
    // At the top-end corner of the round button.
    final button = tester.getRect(find.byType(RoundOutlinedButton));
    final count = tester.getCenter(find.text('3'));
    expect(count.dx, greaterThan(button.center.dx));
    expect(count.dy, lessThan(button.center.dy));
  });
}
