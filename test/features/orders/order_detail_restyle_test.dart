// Order tracking, invoice and review on the white search-style page: the
// tracking journey (a painted stepper that fills, breathes three times and
// rests), notices that open and fold with the order, the "Your items" list
// with its invoice link, the invoice's three sections, the review stars
// (44 dp targets read "Rate n of 5", a cascading fill) and the submit pill
// that refuses until a star is set — in English and Arabic, at 360 dp and
// text scale 1.3 without overflow.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/core/data/mappers/order_mapper.dart';
import 'package:hero_mart/src/core/data/models/order_model.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/responsive/app_size.dart';
import 'package:hero_mart/src/core/widgets/hero_money_text.dart';
import 'package:hero_mart/src/core/widgets/hero_submit_button.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/submit_product_review_usecase.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/order_review_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/order_tracking_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/invoice/invoice_body.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/order_line_row.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/review/review_body.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/review/review_product_tile.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/review/review_star_icon.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/review/review_submit_bar.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/tracking/order_tracking_view.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/tracking/tracking_body.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/tracking/tracking_progress_painter.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/tracking/tracking_progress_stepper.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/tracking/tracking_status_header.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_order_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/rebuild_probe.dart';
import 'fake_orders_repository.dart';
import 'order_test_fixtures.dart';

const Locale _en = Locale('en');
const Locale _ar = Locale('ar');

/// Review tiles show product pictures; a line without one draws a static
/// placeholder instead of a network image that would shimmer forever.
class _NoImageOrdersRepository extends FakeOrdersRepository {
  @override
  OrderEntity order({String id = 'o1', String status = 'placed'}) {
    final json = orderJson(id: id, status: status);
    final line = orderLineJson();
    (line['product'] as Map<String, dynamic>)['image'] = '';
    json['lines'] = <Map<String, dynamic>>[line];
    return OrderModel.fromJson(json).toEntity();
  }
}

OrderEntity _order({
  String status = 'placed',
  Map<String, dynamic>? cancellation,
  Map<String, dynamic>? picking,
  Map<String, dynamic>? delivery,
}) => OrderModel.fromJson(
  orderJson(
    status: status,
    cancellation: cancellation,
    picking: picking,
    delivery: delivery,
  ),
).toEntity();

/// A cancelled order that went through picking: every optional block shows.
OrderEntity _busyOrder({String status = 'picking'}) => _order(
  status: status,
  cancellation: status == 'cancelled'
      ? const <String, dynamic>{'cancelledBy': 'customer', 'note': 'Too late'}
      : null,
  picking: const <String, dynamic>{
    'picker': <String, dynamic>{'name': 'Ali'},
    'unavailableLines': <Map<String, dynamic>>[
      <String, dynamic>{'lineKey': 'l2'},
    ],
    'substitutedLines': <Map<String, dynamic>>[
      <String, dynamic>{
        'lineKey': 'l1',
        'product': <String, dynamic>{
          'name': <String, dynamic>{'en': 'Jasmine rice', 'ar': 'أرز ياسمين'},
        },
      },
    ],
  },
  delivery: const <String, dynamic>{
    'driver': <String, dynamic>{'name': 'Sam'},
  },
);

OrderTrackingCubit _trackingCubit(FakeOrdersRepository repository) =>
    OrderTrackingCubit(
      watchOrder: WatchOrderUseCase(repository),
      cancelOrder: CancelOrderUseCase(repository),
    );

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Locale locale = _en,
  double textScale = 1,
  bool reduceMotion = false,
  Size? size,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }
  // Formatters read Intl.defaultLocale (LocalizationCubit keeps it in sync
  // in the app); EasyLocalization alone does not set it.
  Intl.defaultLocale = locale.languageCode;
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: Routes.orderInvoice,
        builder: (_, state) => Scaffold(body: Text('invoice:${state.extra}')),
      ),
      GoRoute(
        path: Routes.login,
        builder: (_, _) => const Scaffold(body: Text('login')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[_en, _ar],
        path: 'assets/i18n',
        fallbackLocale: _en,
        startLocale: locale,
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp.router(
            routerConfig: router,
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
                disableAnimations: reduceMotion,
              ),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pump();
  // A locale whose file is not cached yet loads on the real event loop:
  // wait (boundedly) until the screen is actually on stage.
  for (var i = 0; i < 50 && find.byWidget(home).evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  expect(find.byWidget(home), findsOneWidget);
}

Widget _trackingHome(OrderTrackingCubit cubit, Widget body) =>
    BlocProvider<OrderTrackingCubit>.value(
      value: cubit,
      child: Scaffold(body: body),
    );

double _starScale(WidgetTester tester, int star) {
  final icon = find.descendant(
    of: find.byKey(ValueKey<int>(star)),
    matching: find.byType(ReviewStarIcon),
  );
  final scale = find.descendant(
    of: icon,
    matching: find.byType(ScaleTransition),
  );
  return tester.widget<ScaleTransition>(scale).scale.value;
}

TrackingProgressPainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(TrackingProgressStepper),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as TrackingProgressPainter;

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting();
  });

  tearDown(() => Intl.defaultLocale = null);

  late _NoImageOrdersRepository reviewRepository;
  late OrderReviewCubit reviewCubit;

  /// The review body over a real cubit on the fake (a delivered order with
  /// one unrated product). Bounded pumps only: nothing here must settle.
  Future<void> pumpReview(
    WidgetTester tester, {
    Locale locale = _en,
    double textScale = 1,
    bool reduceMotion = false,
    Size? size,
  }) async {
    reviewRepository = _NoImageOrdersRepository()..detailStatus = 'delivered';
    reviewCubit = OrderReviewCubit(
      watchOrder: WatchOrderUseCase(reviewRepository),
      submitReview: SubmitProductReviewUseCase(reviewRepository),
    );
    addTearDown(reviewCubit.close);
    await tester.runAsync(() => reviewCubit.load('o1'));
    await _pump(
      tester,
      BlocProvider<OrderReviewCubit>.value(
        value: reviewCubit,
        child: Scaffold(body: ReviewBody(order: reviewCubit.state.order!)),
      ),
      locale: locale,
      textScale: textScale,
      reduceMotion: reduceMotion,
      size: size,
    );
    await tester.pump(const Duration(milliseconds: 400));
  }

  group('tracking', () {
    testWidgets('the journey, the items and the invoice link (en)', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(FakeOrdersRepository());
      addTearDown(trackingCubit.close);
      await _pump(
        tester,
        _trackingHome(trackingCubit, TrackingBody(order: _order())),
      );
      await tester.pumpAndSettle();

      expect(find.text('Placed'), findsOneWidget);
      expect(find.textContaining('Arrives in about 45'), findsOneWidget);
      expect(find.text('Deliver to'), findsOneWidget);
      expect(find.text('Your items'), findsOneWidget);
      expect(find.text('Basmati rice'), findsOneWidget);
      expect(find.text('2×'), findsOneWidget);
      expect(find.text('KD 3.000'), findsOneWidget); // the line
      expect(find.text('KD 3.500'), findsOneWidget); // the order total

      await tester.ensureVisible(find.text('Invoice'));
      await tester.tap(find.text('Invoice'));
      await tester.pumpAndSettle();
      expect(find.text('invoice:o1'), findsOneWidget);
    });

    testWidgets('cancel shows while the order can be cancelled, then folds', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(FakeOrdersRepository());
      addTearDown(trackingCubit.close);
      final order = ValueNotifier<OrderEntity>(_order());
      addTearDown(order.dispose);
      await _pump(
        tester,
        _trackingHome(
          trackingCubit,
          ValueListenableBuilder<OrderEntity>(
            valueListenable: order,
            builder: (_, value, _) => TrackingBody(order: value),
          ),
        ),
        size: const Size(400, 1200),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cancel order'), findsOneWidget);

      order.value = _order(
        status: 'cancelled',
        cancellation: const <String, dynamic>{'cancelledBy': 'staff'},
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Folding: the last button is still drawn, but no longer tappable.
      expect(find.text('Cancel order'), findsOneWidget);
      expect(find.text('Cancelled by the store'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Cancel order'), findsNothing);
      expect(find.byType(TrackingProgressStepper), findsNothing);

      // A delivered order never offered it.
      order.value = _order(status: 'delivered');
      await tester.pumpAndSettle();
      expect(find.text('Cancel order'), findsNothing);
    });

    testWidgets('the cancellation, picking and delivery notices render', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(FakeOrdersRepository());
      addTearDown(trackingCubit.close);
      await _pump(
        tester,
        _trackingHome(
          trackingCubit,
          TrackingBody(order: _busyOrder(status: 'cancelled')),
        ),
        size: const Size(400, 1200),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Cancelled by you'), findsOneWidget);
      expect(find.text('Note: Too late'), findsOneWidget);
      expect(find.text('Changes while picking'), findsOneWidget);
      expect(find.text('1 items were unavailable'), findsOneWidget);
      expect(find.text('Jasmine rice was substituted'), findsOneWidget);
      expect(find.text('Picker: Ali'), findsOneWidget);
      expect(find.text('Driver: Sam'), findsOneWidget);
      // A cancelled order has left the journey.
      expect(find.byType(TrackingProgressStepper), findsNothing);
      expect(find.text('Cancel order'), findsNothing);
    });

    testWidgets('the stepper reads "Step 2 of 6", fills, breathes, rests', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final trackingCubit = _trackingCubit(FakeOrdersRepository());
      addTearDown(trackingCubit.close);
      await _pump(
        tester,
        _trackingHome(
          trackingCubit,
          TrackingBody(order: _order(status: 'confirmed')),
        ),
      );

      expect(find.bySemanticsLabel('Step 2 of 6'), findsOneWidget);
      // The first build is the start of the sweep, not the end state.
      expect(_painter(tester).fill.value, lessThan(2));
      // The page's first sweep holds while the body fades in, so it is seen.
      await tester.pump(const Duration(milliseconds: 100));
      expect(_painter(tester).fill.value, 0);

      await tester.pump(const Duration(seconds: 1)); // sweep done
      await tester.pump(const Duration(milliseconds: 100)); // breathing
      expect(_painter(tester).fill.value, 2);
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pump(const Duration(seconds: 4)); // three breaths later
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
      expect(_painter(tester).pulse.value, 0);
      semantics.dispose();
    });

    testWidgets('a poll that moves the step fills on from the old step', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(FakeOrdersRepository());
      addTearDown(trackingCubit.close);
      final order = ValueNotifier<OrderEntity>(_order());
      addTearDown(order.dispose);
      await _pump(
        tester,
        _trackingHome(
          trackingCubit,
          ValueListenableBuilder<OrderEntity>(
            valueListenable: order,
            builder: (_, value, _) => TrackingBody(order: value),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_painter(tester).fill.value, 1);

      order.value = _order(status: 'picking');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final mid = _painter(tester).fill.value;
      expect(mid, greaterThan(1));
      expect(mid, lessThan(3));
      await tester.pumpAndSettle();
      expect(_painter(tester).fill.value, 3);
      expect(find.text('Being picked'), findsOneWidget);
    });

    testWidgets('a poll rebuilds the status, never the unchanged lines', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(FakeOrdersRepository());
      addTearDown(trackingCubit.close);
      // A counter beside the order, so an equal (fresh) order still reaches
      // the body — as a poll does when its BlocBuilder lets it through.
      final poll = ValueNotifier<(int, OrderEntity)>((0, _order()));
      addTearDown(poll.dispose);
      await _pump(
        tester,
        _trackingHome(
          trackingCubit,
          ValueListenableBuilder<(int, OrderEntity)>(
            valueListenable: poll,
            builder: (_, value, _) => TrackingBody(order: value.$2),
          ),
        ),
        size: const Size(400, 1200),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OrderLineRow), findsOneWidget);
      final builds = RebuildProbe<Widget, Type>((w) => w.runtimeType)..start();
      addTearDown(builds.stop);

      // The same order again: the body rebuilds, the lines do not.
      poll.value = (1, _order());
      await tester.pump();
      expect(builds.of(TrackingBody), 1);
      expect(builds.of(OrderLineRow), 0);

      // The status moved, the lines did not: header yes, lines no.
      builds.reset();
      poll.value = (2, _order(status: 'confirmed'));
      await tester.pump();
      expect(builds.of(TrackingStatusHeader), 1);
      expect(builds.of(OrderLineRow), 0);
      await tester.pumpAndSettle();
      expect(find.text('Confirmed'), findsOneWidget);

      // A line changed: its row rebuilds.
      builds.reset();
      poll.value = (
        3,
        OrderModel.fromJson(
          orderJson(
            status: 'confirmed',
            lines: <Map<String, dynamic>>[orderLineJson(quantity: 3)],
          ),
        ).toEntity(),
      );
      await tester.pump();
      expect(builds.of(OrderLineRow), 1);
      expect(find.text('3×'), findsOneWidget);
    });

    testWidgets('reduced motion paints the step at once and runs nothing', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(FakeOrdersRepository());
      addTearDown(trackingCubit.close);
      await _pump(
        tester,
        _trackingHome(
          trackingCubit,
          TrackingBody(order: _order(status: 'confirmed')),
        ),
        reduceMotion: true,
      );

      expect(_painter(tester).fill.value, 2);
      expect(_painter(tester).pulse.value, 0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('the page: title bar, and the signed-out state signs in', (
      tester,
    ) async {
      final trackingRepository = FakeOrdersRepository()
        ..detailFailure = const UnauthorizedFailure();
      final trackingCubit = _trackingCubit(trackingRepository);
      addTearDown(trackingCubit.close);
      await tester.runAsync(() => trackingCubit.load('o1'));
      await _pump(
        tester,
        BlocProvider<OrderTrackingCubit>.value(
          value: trackingCubit,
          child: const OrderTrackingView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order tracking'), findsOneWidget);
      expect(find.text('Sign in to see your orders'), findsOneWidget);
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('the page: an error offers a retry that fetches again', (
      tester,
    ) async {
      final trackingRepository = FakeOrdersRepository()
        ..detailFailure = const NotFoundFailure('gone');
      final trackingCubit = _trackingCubit(trackingRepository);
      addTearDown(trackingCubit.close);
      await tester.runAsync(() => trackingCubit.load('o1'));
      await _pump(
        tester,
        BlocProvider<OrderTrackingCubit>.value(
          value: trackingCubit,
          child: const OrderTrackingView(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("This order isn't available"), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(trackingRepository.calls, <String>['getOrder:o1', 'getOrder:o1']);
      expect(find.byType(TrackingBody), findsOneWidget);
      // The retry armed the 30 s poll inside the fake clock: hiding the page
      // disarms it, as leaving the route would.
      trackingCubit.setVisible(false);
    });

    testWidgets('a page pushed over tracking rebuilds none of the page', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(FakeOrdersRepository());
      addTearDown(trackingCubit.close);
      await tester.runAsync(() => trackingCubit.load('o1'));
      await _pump(
        tester,
        BlocProvider<OrderTrackingCubit>.value(
          value: trackingCubit,
          child: const OrderTrackingView(),
        ),
        size: const Size(400, 1200),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OrderLineRow), findsOneWidget);
      final builds = RebuildProbe<Widget, Type>((w) => w.runtimeType)..start();
      addTearDown(builds.stop);

      // The route above flips the page's route status on push and on pop.
      await tester.tap(find.text('Invoice'));
      await tester.pumpAndSettle();
      expect(find.text('invoice:o1'), findsOneWidget);
      GoRouter.of(tester.element(find.text('invoice:o1'))).pop();
      await tester.pumpAndSettle();

      expect(find.byType(TrackingBody), findsOneWidget);
      expect(builds.of(TrackingBody), 0);
      expect(builds.of(OrderLineRow), 0);
      trackingCubit.setVisible(false); // disarms the poll the load armed
    });
  });

  group('invoice', () {
    testWidgets('three sections, no invoice link, the server totals', (
      tester,
    ) async {
      await _pump(
        tester,
        Scaffold(body: InvoiceBody(order: _order())),
        size: const Size(400, 1400),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order info'), findsOneWidget);
      expect(find.text('Your items'), findsOneWidget);
      expect(find.text('Payment summary'), findsOneWidget);
      expect(find.text('Invoice'), findsNothing);
      expect(find.text('JM-1001'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('KD 0.500'), findsOneWidget); // delivery fee
      expect(find.text('KD 3.500'), findsNWidgets(2)); // items + summary
      expect(find.text('You earned 35 points'), findsOneWidget);
    });
  });

  group('review', () {
    testWidgets('submit refuses until a star is set; stars are labelled', (
      tester,
    ) async {
      await pumpReview(tester);

      expect(find.text('Add a comment'), findsOneWidget);
      for (var star = 1; star <= 5; star++) {
        expect(find.byTooltip('Rate $star of 5'), findsOneWidget);
      }

      await tester.tap(find.byType(HeroSubmitButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        reviewRepository.calls.where((c) => c.startsWith('review:')),
        isEmpty,
      );

      await tester.tap(find.byTooltip('Rate 3 of 5'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(reviewCubit.state.draft.ratingOf('p1'), 3);

      await tester.tap(find.byType(HeroSubmitButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(reviewRepository.calls, contains('review:p1:3'));
      expect(reviewCubit.state.submitted, isTrue);
      // The pill keeps its label and takes no tap; the check is the page's
      // busy overlay (not pumped here).
      expect(
        tester.widget<HeroSubmitButton>(find.byType(HeroSubmitButton)).holding,
        isTrue,
      );
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('a multi-star fill cascades from the previous rating', (
      tester,
    ) async {
      await pumpReview(tester);
      for (var star = 1; star <= 5; star++) {
        expect(_starScale(tester, star), 0);
      }

      await tester.tap(find.byTooltip('Rate 3 of 5'));
      await tester.pump(); // the rating lands
      await tester.pump(); // the pops start
      await tester.pump(const Duration(milliseconds: 20));
      expect(_starScale(tester, 1), greaterThan(0));
      expect(_starScale(tester, 3), 0); // waits two steps
      await tester.pump(const Duration(milliseconds: 500));
      expect(_starScale(tester, 1), 1);
      expect(_starScale(tester, 2), 1);
      expect(_starScale(tester, 3), 1);
      expect(_starScale(tester, 4), 0);

      await tester.tap(find.byTooltip('Rate 1 of 5'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_starScale(tester, 1), 1);
      expect(_starScale(tester, 2), 0);
      expect(_starScale(tester, 3), 0);
    });

    testWidgets('a star rebuilds its tile and the bar, never the list', (
      tester,
    ) async {
      await pumpReview(tester);
      final builds = RebuildProbe<Widget, Type>((w) => w.runtimeType)..start();
      addTearDown(builds.stop);

      // The first star flips "can submit": the tile and the bar rebuild.
      await tester.tap(find.byTooltip('Rate 5 of 5'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(builds.of(ReviewProductTile), 1);
      expect(builds.of(ReviewSubmitBar), 1);
      expect(builds.of(ReviewBody), 0);

      // Another star: only the tile.
      builds.reset();
      await tester.tap(find.byTooltip('Rate 4 of 5'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(builds.of(ReviewProductTile), 1);
      expect(builds.of(ReviewSubmitBar), 0);
      expect(builds.of(ReviewBody), 0);
      expect(reviewCubit.state.draft.ratingOf('p1'), 4);
    });

    testWidgets('typing a comment rebuilds no tile, bar or list', (
      tester,
    ) async {
      await pumpReview(tester);
      final builds = RebuildProbe<Widget, Type>((w) => w.runtimeType)..start();
      addTearDown(builds.stop);

      await tester.enterText(find.byType(TextField), 'Fresh and quick');
      await tester.pump();
      expect(reviewCubit.state.draft.comment, 'Fresh and quick');
      expect(builds.of(ReviewProductTile), 0);
      expect(builds.of(ReviewSubmitBar), 0);
      expect(builds.of(ReviewBody), 0);
    });

    testWidgets('reduced motion fills the stars at once', (tester) async {
      await pumpReview(tester, reduceMotion: true);

      await tester.tap(find.byTooltip('Rate 4 of 5'));
      await tester.pump();
      for (var star = 1; star <= 4; star++) {
        expect(_starScale(tester, star), 1);
      }
      expect(_starScale(tester, 5), 0);
      // The only thing still moving is Material's tap ink on the star (not
      // ours, not motion-guarded); once it fades, nothing runs.
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
      expect(_starScale(tester, 4), 1);
    });
  });

  group('locales and small screens', () {
    for (final locale in <Locale>[_en, _ar]) {
      testWidgets('tracking at 360 dp, text x1.3 (${locale.languageCode})', (
        tester,
      ) async {
        final trackingCubit = _trackingCubit(FakeOrdersRepository());
        addTearDown(trackingCubit.close);
        await _pump(
          tester,
          _trackingHome(trackingCubit, TrackingBody(order: _busyOrder())),
          locale: locale,
          textScale: 1.3,
          size: const Size(360, 800),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final rtl = locale == _ar;
        expect(
          Directionality.of(tester.element(find.byType(TrackingBody))),
          rtl ? TextDirection.rtl : TextDirection.ltr,
        );
        // The lines are a lazy sliver below the notices: scroll to them.
        await tester.scrollUntilVisible(
          find.byType(OrderLineRow),
          AppSize.s120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // Money is one left-to-right run in both languages.
        final money = find.byType(HeroMoneyText).first;
        final run = tester.widget<Directionality>(
          find.descendant(of: money, matching: find.byType(Directionality)),
        );
        expect(run.textDirection, TextDirection.ltr);
        expect(
          find.descendant(of: money, matching: find.byType(Text)),
          findsOneWidget,
        );
        expect(find.text(rtl ? 'د.ك 3.000' : 'KD 3.000'), findsOneWidget);
      });

      testWidgets('invoice at 360 dp, text x1.3 (${locale.languageCode})', (
        tester,
      ) async {
        await _pump(
          tester,
          Scaffold(body: InvoiceBody(order: _busyOrder())),
          locale: locale,
          textScale: 1.3,
          size: const Size(360, 800),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('review at 360 dp, text x1.3 (${locale.languageCode})', (
        tester,
      ) async {
        await pumpReview(
          tester,
          locale: locale,
          textScale: 1.3,
          size: const Size(360, 800),
        );
        expect(tester.takeException(), isNull);
        expect(
          find.byTooltip(locale == _ar ? 'تقييم 3 من 5' : 'Rate 3 of 5'),
          findsOneWidget,
        );
      });
    }
  });
}
