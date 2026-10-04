// The order page (tracking + details, delivery-app style), the invoice and
// the review: the status panel (the time, the stage in words, the painted
// four-stage bar whose band runs a while and rests), the blocks that open
// and fold with the order one after another, the delivered moment, the
// items card folded to three, the invoice's three sections, the review
// stars (44 dp targets read "Rate n of 5", a cascading fill) and the submit
// pill that refuses until a star is set — in English and Arabic, at 360 dp
// and text scale 1.3 without overflow.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hero_mart/src/config/routes/route_args/order_review_args.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/core/data/mappers/order_mapper.dart';
import 'package:hero_mart/src/core/data/models/order_model.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/motion/confetti_burst.dart';
import 'package:hero_mart/src/core/motion/haptics.dart';
import 'package:hero_mart/src/core/responsive/app_size.dart';
import 'package:hero_mart/src/core/utils/formatters.dart';
import 'package:hero_mart/src/core/widgets/hero_money_text.dart';
import 'package:hero_mart/src/core/widgets/hero_submit_button.dart';
import 'package:hero_mart/src/core/widgets/hero_title_bar.dart';
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
import 'package:hero_mart/src/features/orders/presentation/widgets/tracking/tracking_rate_star.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/tracking/tracking_rate_thanks.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/tracking/tracking_stage_bar.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/tracking/tracking_stage_bar_painter.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/tracking/tracking_status_hero.dart';
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

/// [json] with no product pictures (a network image would shimmer forever
/// under the test clock).
OrderEntity _withoutImages(Map<String, dynamic> json) {
  for (final line in json['lines'] as List<Map<String, dynamic>>) {
    (line['product'] as Map<String, dynamic>)['image'] = '';
  }
  return OrderModel.fromJson(json).toEntity();
}

OrderEntity _order({
  String status = 'placed',
  Map<String, dynamic>? cancellation,
  Map<String, dynamic>? picking,
  Map<String, dynamic>? delivery,
}) => _withoutImages(
  orderJson(
    status: status,
    cancellation: cancellation,
    picking: picking,
    delivery: delivery,
  ),
);

/// [order] as if it had been placed at [createdAt].
OrderEntity _withCreatedAt(OrderEntity order, DateTime createdAt) =>
    OrderEntity(
      id: order.id,
      orderNumber: order.orderNumber,
      status: order.status,
      address: order.address,
      branch: order.branch,
      lines: order.lines,
      subtotalFils: order.subtotalFils,
      deliveryFeeFils: order.deliveryFeeFils,
      totalFils: order.totalFils,
      etaMinutes: order.etaMinutes,
      payment: order.payment,
      picking: order.picking,
      delivery: order.delivery,
      createdAt: createdAt,
    );

/// The order page's body over [order], help going nowhere.
Widget _body(OrderEntity order) => TrackingBody(order: order, onHelp: () {});

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
      // The review as the rating card sees it: it closes with `true` once
      // the review went through, with nothing when the customer backs out.
      GoRoute(
        path: Routes.orderReview,
        builder: (_, state) => Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                Text('review:${(state.extra! as OrderReviewArgs).rating}'),
                TextButton(
                  onPressed: () => context.pop(true),
                  child: const Text('review-sent'),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('review-back'),
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(
        path: Routes.orders,
        builder: (_, _) => const Scaffold(body: Text('orders-list')),
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

TrackingStageBarPainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(TrackingStageBar),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as TrackingStageBarPainter;

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
      final trackingCubit = _trackingCubit(_NoImageOrdersRepository());
      addTearDown(trackingCubit.close);
      await _pump(
        tester,
        _trackingHome(trackingCubit, _body(_order())),
        size: const Size(400, 1400),
      );
      await tester.pumpAndSettle();

      // No time to promise (the week-old estimate has passed): the stage
      // leads the panel, with the "late" plate under it.
      expect(find.text('Order received'), findsOneWidget);
      expect(find.text('Waiting for the store to confirm it'), findsOneWidget);
      expect(find.textContaining('Running a little late'), findsOneWidget);
      expect(find.text('Delivery details'), findsOneWidget);
      expect(find.text('As soon as possible'), findsOneWidget);
      expect(find.text('Order summary'), findsOneWidget);
      expect(find.text('Basmati rice'), findsOneWidget);
      expect(find.text('2×'), findsOneWidget);
      expect(find.text('KD 3.000'), findsNWidgets(2)); // the line + subtotal
      expect(find.text('KD 3.500'), findsOneWidget); // the order total
      expect(find.text('Cash on delivery'), findsOneWidget);
      expect(find.text('Pay on delivery'), findsOneWidget);
      expect(find.text('JM-1001'), findsOneWidget);

      await tester.ensureVisible(find.text('View invoice'));
      await tester.pump();
      await tester.tap(find.text('View invoice'));
      await tester.pumpAndSettle();
      expect(find.text('invoice:o1'), findsOneWidget);
    });

    testWidgets('a fresh order counts down to its rounded-up time', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(_NoImageOrdersRepository());
      addTearDown(trackingCubit.close);
      // Placed now with a 45 min estimate: 40–50 min left, never late.
      final order = _withCreatedAt(_order(status: 'picking'), DateTime.now());
      await _pump(tester, _trackingHome(trackingCubit, _body(order)));
      await tester.pumpAndSettle();

      expect(find.text('Arriving in'), findsOneWidget);
      expect(find.textContaining(RegExp(r'^(4\d|50) min$')), findsOneWidget);
      expect(find.textContaining('Estimated at'), findsOneWidget);
      expect(find.textContaining('Running a little late'), findsNothing);
      // The stage moves under the bar.
      expect(find.text('Packing your order'), findsOneWidget);
    });

    testWidgets('cancel shows while the order can be cancelled, then folds', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(_NoImageOrdersRepository());
      addTearDown(trackingCubit.close);
      final order = ValueNotifier<OrderEntity>(_order());
      addTearDown(order.dispose);
      await _pump(
        tester,
        _trackingHome(
          trackingCubit,
          ValueListenableBuilder<OrderEntity>(
            valueListenable: order,
            builder: (_, value, _) => _body(value),
          ),
        ),
        size: const Size(400, 1600),
      );
      await tester.pumpAndSettle();
      expect(find.text('Cancel order'), findsOneWidget);
      expect(find.byType(TrackingStageBar), findsOneWidget);

      order.value = _order(
        status: 'cancelled',
        cancellation: const <String, dynamic>{'cancelledBy': 'staff'},
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // One after another (B2-03): the panel has answered, the notice and
      // the button still wait their turn — the last button is still drawn,
      // but no longer tappable.
      expect(find.text('Order cancelled'), findsOneWidget);
      expect(find.text('Cancelled by the store'), findsOneWidget);
      expect(find.text('Cancel order'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Cancelled by the store'), findsNWidgets(2));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Cancel order'), findsNothing);
      expect(find.byType(TrackingStageBar), findsNothing);

      // A delivered order never offered it.
      order.value = _order(status: 'delivered');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(find.text('Cancel order'), findsNothing);
    });

    testWidgets('the cancellation and picking notices, the marked lines', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(_NoImageOrdersRepository());
      addTearDown(trackingCubit.close);
      await _pump(
        tester,
        _trackingHome(trackingCubit, _body(_busyOrder(status: 'cancelled'))),
        size: const Size(400, 1600),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order cancelled'), findsOneWidget);
      // The panel's line and the notice's title.
      expect(find.text('Cancelled by you'), findsNWidgets(2));
      expect(find.text('Note: Too late'), findsOneWidget);
      expect(find.text('Changes while picking'), findsOneWidget);
      expect(find.text('Unavailable items: 1'), findsOneWidget);
      expect(find.text('Replaced items: 1'), findsOneWidget);
      // The replaced line says what came instead.
      expect(
        find.textContaining(
          'Replaced with ${Formatters.isolate('Jasmine rice')}',
          findRichText: true,
        ),
        findsOneWidget,
      );
      // A cancelled order has left the journey; nobody is handling it.
      expect(find.byType(TrackingStageBar), findsNothing);
      expect(find.text('Your picker'), findsNothing);
      expect(find.text('Cancel order'), findsNothing);
    });

    testWidgets('the picker and the driver, with "Now" on the driver', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(_NoImageOrdersRepository());
      addTearDown(trackingCubit.close);
      await _pump(
        tester,
        _trackingHome(
          trackingCubit,
          _body(_busyOrder(status: 'out_for_delivery')),
        ),
        size: const Size(400, 1600),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ali'), findsOneWidget);
      expect(find.text('Your picker'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
      expect(find.text('Your driver'), findsOneWidget);
      expect(find.text('Now'), findsOneWidget);
      expect(find.text('Sam is bringing your order'), findsOneWidget);
    });

    testWidgets('the bar reads its stage, runs its band a while, rests', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final trackingCubit = _trackingCubit(_NoImageOrdersRepository());
      addTearDown(trackingCubit.close);
      await _pump(
        tester,
        _trackingHome(trackingCubit, _body(_order(status: 'picking'))),
      );

      expect(find.bySemanticsLabel('Packing. Step 2 of 4'), findsOneWidget);
      // Drawn at the order's stage at once: no sweep on every visit.
      expect(_painter(tester).fill.value, 1);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.hasRunningAnimations, isTrue); // the band runs

      // Past the ambient budget everything rests.
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isFalse);
      expect(_painter(tester).sweep.value, 0);
      semantics.dispose();
    });

    testWidgets('a poll that moves the stage fills on from the old stage', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(_NoImageOrdersRepository());
      addTearDown(trackingCubit.close);
      final order = ValueNotifier<OrderEntity>(_order());
      addTearDown(order.dispose);
      await _pump(
        tester,
        _trackingHome(
          trackingCubit,
          ValueListenableBuilder<OrderEntity>(
            valueListenable: order,
            builder: (_, value, _) => _body(value),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_painter(tester).fill.value, 0);

      order.value = _order(status: 'picking');
      await tester.pump();
      // The headline answers first; the bar follows a beat later.
      expect(find.text('Packing your order'), findsOneWidget);
      expect(_painter(tester).fill.value, 0);
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump(const Duration(milliseconds: 200));
      final mid = _painter(tester).fill.value;
      expect(mid, greaterThan(0));
      expect(mid, lessThan(1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(_painter(tester).fill.value, 1);
    });

    testWidgets('a poll rebuilds the status, never the unchanged lines', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(_NoImageOrdersRepository());
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
            builder: (_, value, _) => _body(value.$2),
          ),
        ),
        size: const Size(400, 1400),
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

      // The status moved, the lines did not: the panel yes, lines no.
      builds.reset();
      poll.value = (2, _order(status: 'confirmed'));
      await tester.pump();
      expect(builds.of(TrackingStatusHero), 1);
      expect(builds.of(OrderLineRow), 0);
      await tester.pumpAndSettle();
      expect(find.text('Order confirmed'), findsOneWidget);

      // A line changed: its row rebuilds.
      builds.reset();
      poll.value = (
        3,
        _withoutImages(
          orderJson(
            status: 'confirmed',
            lines: <Map<String, dynamic>>[orderLineJson(quantity: 3)],
          ),
        ),
      );
      await tester.pump();
      expect(builds.of(OrderLineRow), 1);
      expect(find.text('3×'), findsOneWidget);
    });

    testWidgets('more than three items fold behind "Show N more"', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(_NoImageOrdersRepository());
      addTearDown(trackingCubit.close);
      final order = _withoutImages(
        orderJson(
          lines: <Map<String, dynamic>>[
            for (var i = 1; i <= 5; i++)
              orderLineJson(key: 'l$i', productId: 'p$i'),
          ],
        ),
      );
      await _pump(
        tester,
        _trackingHome(trackingCubit, _body(order)),
        size: const Size(400, 1800),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OrderLineRow), findsNWidgets(3));

      await tester.ensureVisible(find.text('Show 2 more'));
      await tester.tap(find.text('Show 2 more'));
      await tester.pumpAndSettle();
      expect(find.byType(OrderLineRow), findsNWidgets(5));

      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();
      expect(find.byType(OrderLineRow), findsNWidgets(3));
    });

    testWidgets('reduced motion paints the stage at once and runs nothing', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(_NoImageOrdersRepository());
      addTearDown(trackingCubit.close);
      await _pump(
        tester,
        _trackingHome(trackingCubit, _body(_order(status: 'picking'))),
        reduceMotion: true,
      );

      expect(_painter(tester).fill.value, 1);
      expect(_painter(tester).sweep.value, 0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('the page: title bar, and the signed-out state signs in', (
      tester,
    ) async {
      final trackingRepository = _NoImageOrdersRepository()
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

      expect(find.text('Order details'), findsOneWidget);
      expect(find.text('Help'), findsOneWidget);
      expect(find.text('Sign in to see your orders'), findsOneWidget);
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('login'), findsOneWidget);
    });

    testWidgets('the page: an error offers a retry that fetches again', (
      tester,
    ) async {
      final trackingRepository = _NoImageOrdersRepository()
        ..detailFailure = const ServerFailure('boom', statusCode: 500);
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

      await tester.tap(find.text('Retry'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(trackingRepository.calls, <String>['getOrder:o1', 'getOrder:o1']);
      expect(find.byType(TrackingBody), findsOneWidget);
      // The number arrived with the order: the title says it.
      expect(
        find.descendant(
          of: find.byType(HeroTitleBar),
          matching: find.textContaining('JM-1001'),
        ),
        findsOneWidget,
      );
      // The retry armed the 30 s poll inside the fake clock: hiding the page
      // disarms it, as leaving the route would.
      trackingCubit.setVisible(false);
    });

    testWidgets('the page: a gone order offers the way back, no retry', (
      tester,
    ) async {
      final trackingRepository = _NoImageOrdersRepository()
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
      expect(find.text('Retry'), findsNothing);
      await tester.tap(find.text('Back to orders'));
      await tester.pumpAndSettle();
      expect(find.text('orders-list'), findsOneWidget);
    });

    testWidgets('a page pushed over tracking rebuilds none of the page', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(_NoImageOrdersRepository());
      addTearDown(trackingCubit.close);
      await tester.runAsync(() => trackingCubit.load('o1'));
      await _pump(
        tester,
        BlocProvider<OrderTrackingCubit>.value(
          value: trackingCubit,
          child: const OrderTrackingView(),
        ),
        size: const Size(400, 1600),
      );
      await tester.pumpAndSettle();
      expect(find.byType(OrderLineRow), findsOneWidget);
      await tester.ensureVisible(find.text('View invoice'));
      await tester.pumpAndSettle();
      final builds = RebuildProbe<Widget, Type>((w) => w.runtimeType)..start();
      addTearDown(builds.stop);

      // The route above flips the page's route status on push and on pop.
      await tester.tap(find.text('View invoice'));
      await tester.pumpAndSettle();
      expect(find.text('invoice:o1'), findsOneWidget);
      GoRouter.of(tester.element(find.text('invoice:o1'))).pop();
      await tester.pumpAndSettle();

      expect(find.byType(TrackingBody), findsOneWidget);
      expect(builds.of(TrackingBody), 0);
      expect(builds.of(OrderLineRow), 0);
      trackingCubit.setVisible(false); // disarms the poll the load armed
    });

    testWidgets('delivered live: the success moment, then the rating card', (
      tester,
    ) async {
      Haptics.debugReset();
      final haptics = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') haptics.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final trackingCubit = _trackingCubit(_NoImageOrdersRepository());
      addTearDown(trackingCubit.close);
      final order = ValueNotifier<OrderEntity>(
        _order(status: 'out_for_delivery'),
      );
      addTearDown(order.dispose);
      await _pump(
        tester,
        _trackingHome(
          trackingCubit,
          ValueListenableBuilder<OrderEntity>(
            valueListenable: order,
            builder: (_, value, _) => _body(value),
          ),
        ),
        size: const Size(400, 1600),
      );
      await tester.pumpAndSettle();
      expect(haptics, isEmpty);
      expect(find.text('How was your order?'), findsNothing);

      order.value = _order(status: 'delivered');
      await tester.pump();
      // The success haptic lands with the panel's answer, before anything
      // else moves.
      expect(haptics, hasLength(1));
      expect(find.text('Order delivered'), findsOneWidget);
      final burst = tester.widget<ConfettiBurst>(find.byType(ConfettiBurst));
      expect(burst.playKey, isNull); // the burst waits for the pop
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester.widget<ConfettiBurst>(find.byType(ConfettiBurst)).playKey,
        1,
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('How was your order?'), findsOneWidget);
      expect(haptics, hasLength(1));
    });

    testWidgets('a delivered order opened later plays no moment', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(_NoImageOrdersRepository());
      addTearDown(trackingCubit.close);
      await _pump(
        tester,
        _trackingHome(trackingCubit, _body(_order(status: 'delivered'))),
        size: const Size(400, 1600),
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<ConfettiBurst>(find.byType(ConfettiBurst)).playKey,
        isNull,
      );
      expect(find.text('Delivered at'), findsOneWidget);
      expect(find.text('How was your order?'), findsOneWidget);
    });

    testWidgets('a review that went through turns the rating card to thanks', (
      tester,
    ) async {
      final trackingCubit = _trackingCubit(_NoImageOrdersRepository());
      addTearDown(trackingCubit.close);
      await _pump(
        tester,
        _trackingHome(trackingCubit, _body(_order(status: 'delivered'))),
        size: const Size(400, 1600),
      );
      await tester.pumpAndSettle();

      // Backing out of the review keeps the question.
      await tester.tap(find.byType(TrackingRateStar).at(1));
      await tester.pumpAndSettle();
      expect(find.text('review:2'), findsOneWidget);
      await tester.tap(find.text('review-back'));
      await tester.pumpAndSettle();
      expect(find.text('How was your order?'), findsOneWidget);
      expect(find.byType(TrackingRateThanks), findsNothing);

      // The stars travel to the review; one that went through says thanks.
      await tester.tap(find.byType(TrackingRateStar).at(3));
      await tester.pumpAndSettle();
      expect(find.text('review:4'), findsOneWidget);
      await tester.tap(find.text('review-sent'));
      await tester.pumpAndSettle();
      expect(find.byType(TrackingRateThanks), findsOneWidget);
      expect(find.text('Thanks for rating!'), findsOneWidget);
      expect(find.text('How was your order?'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('invoice', () {
    testWidgets('the receipt marks what the picker changed', (tester) async {
      await _pump(
        tester,
        Scaffold(
          body: InvoiceBody(order: _busyOrder(status: 'delivered')),
        ),
        size: const Size(400, 1400),
      );
      await tester.pumpAndSettle();

      // Line l1 was substituted (the fixture's l2 is not on the order).
      expect(
        find.textContaining(
          'Replaced with ${Formatters.isolate('Jasmine rice')}',
          findRichText: true,
        ),
        findsOneWidget,
      );
    });

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
      // Cash not handed over yet: the order page's and the PDF's words.
      expect(find.text('Pay on delivery'), findsOneWidget);
      expect(find.text('KD 0.500'), findsOneWidget); // delivery fee
      expect(find.text('KD 3.500'), findsNWidgets(2)); // items + summary
      // Not delivered yet: the points come with the delivery.
      expect(
        find.text("You'll earn 35 points once it's delivered"),
        findsOneWidget,
      );
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
      expect(find.byIcon(HeroIcons.check), findsNothing);
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
        final trackingCubit = _trackingCubit(_NoImageOrdersRepository());
        addTearDown(trackingCubit.close);
        await _pump(
          tester,
          _trackingHome(trackingCubit, _body(_busyOrder())),
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
        // The line and the subtotal.
        expect(find.text(rtl ? 'د.ك 3.000' : 'KD 3.000'), findsWidgets);
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
