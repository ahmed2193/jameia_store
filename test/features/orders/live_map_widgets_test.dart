// The live rider map's surfaces a widget test can reach (the native map
// itself needs a device): the order page's "Track on map" card — shown while
// a delivery is on its way, folded once it is not, opening the live map with
// the order — and the map's bottom panel through a whole ride, in English
// and Arabic, at 360 dp and text scale 1.3 without overflow — and the screen's
// top bar, which stays put while the screen loads, shows the ride and fails.
import 'dart:async';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/core/data/mappers/order_mapper.dart';
import 'package:hero_mart/src/core/data/models/order_model.dart';
import 'package:hero_mart/src/core/domain/entities/order_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/motion/collapse_reveal.dart';
import 'package:hero_mart/src/core/widgets/app_loader.dart';
import 'package:hero_mart/src/core/widgets/failure_view.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_fix.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_route.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_trip.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_vehicle.dart';
import 'package:hero_mart/src/features/orders/domain/entities/rider_chat.dart';
import 'package:hero_mart/src/features/orders/domain/entities/rider_quick_reply.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/cancel_order_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/get_courier_trip_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_courier_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_order_usecase.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/courier_tracking_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/order_tracking_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/rider_chat_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/tracking_alerts_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_body.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_panel.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_scene.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_top_bar.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/tracking/tracking_body.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/tracking/tracking_live_map_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'courier_test_fakes.dart';
import 'fake_orders_repository.dart';
import 'live_map_test_fakes.dart';
import 'order_test_fixtures.dart';

const Locale _en = Locale('en');
const Locale _ar = Locale('ar');

/// [status] with no product pictures (a network image would shimmer
/// forever under the test clock).
OrderEntity _order(String status) {
  final json = orderJson(status: status);
  for (final line in json['lines'] as List<Map<String, dynamic>>) {
    (line['product'] as Map<String, dynamic>)['image'] = '';
  }
  return OrderModel.fromJson(json).toEntity();
}

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Locale locale = _en,
  double textScale = 1,
  Size size = const Size(400, 1400),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: <RouteBase>[
      GoRoute(path: '/', builder: (_, _) => home),
      GoRoute(
        path: Routes.orderLiveMap,
        builder: (_, state) => Scaffold(
          body: Text('live-map:${(state.extra! as OrderEntity).id}'),
        ),
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
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: child!,
            ),
          ),
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pump();
  for (var i = 0; i < 50 && find.byWidget(home).evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  expect(find.byWidget(home), findsOneWidget);
}

bool _revealed(WidgetTester tester, Type child) => tester
    .widget<CollapseReveal>(
      find
          .ancestor(
            of: find.byType(child),
            matching: find.byType(CollapseReveal),
          )
          .first,
    )
    .visible;

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('order page card', () {
    Future<void> pumpOrderPage(WidgetTester tester, OrderEntity order) async {
      final repository = FakeOrdersRepository();
      final cubit = OrderTrackingCubit(
        watchOrder: WatchOrderUseCase(repository),
        cancelOrder: CancelOrderUseCase(repository),
      );
      addTearDown(cubit.close);
      await _pump(
        tester,
        BlocProvider<OrderTrackingCubit>.value(
          value: cubit,
          child: Scaffold(
            body: TrackingBody(order: order, onHelp: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a delivery on its way opens its live map', (tester) async {
      await pumpOrderPage(tester, _order('picking'));

      expect(_revealed(tester, TrackingLiveMapCard), isTrue);
      expect(find.text('Follow your order live'), findsOneWidget);

      await tester.tap(find.text('Track on map'));
      await tester.pumpAndSettle();

      expect(find.text('live-map:o1'), findsOneWidget);
    });

    testWidgets('folded once the order is delivered', (tester) async {
      await pumpOrderPage(tester, _order('delivered'));

      expect(find.byType(TrackingLiveMapCard), findsNothing);
    });
  });

  group('live map panel', () {
    late FakeCourierTrackingRepository repository;
    late CourierTrackingCubit cubit;
    late FakeRiderChatRepository chat;
    late RiderChatCubit chatCubit;

    Future<void> pumpPanel(
      WidgetTester tester, {
      Locale locale = _en,
      double textScale = 1,
      Size size = const Size(400, 900),
      CourierTrip? trip,
    }) async {
      repository = FakeCourierTrackingRepository(trip: trip);
      cubit = CourierTrackingCubit(
        getTrip: GetCourierTripUseCase(repository),
        watchCourier: WatchCourierUseCase(repository),
      );
      addTearDown(cubit.close);
      final alerts = buildTrackingAlertsCubit(FakeLocalAlerts());
      addTearDown(alerts.close);
      chat = FakeRiderChatRepository();
      chatCubit = buildRiderChatCubit(chat);
      addTearDown(chatCubit.close);
      // In the test's own zone: the feed's events then reach the widgets
      // on the next pump.
      await cubit.start(_order('picking'));
      await _pump(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider<CourierTrackingCubit>.value(value: cubit),
            BlocProvider<TrackingAlertsCubit>.value(value: alerts),
            BlocProvider<RiderChatCubit>.value(value: chatCubit),
          ],
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: LiveMapPanel(trip: cubit.state.trip!),
            ),
          ),
        ),
        locale: locale,
        textScale: textScale,
        size: size,
      );
    }

    Future<void> send(WidgetTester tester, CourierFix fix) async {
      repository.feed.add(fix);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('follows the ride from finding a rider to the door', (
      tester,
    ) async {
      await pumpPanel(tester);

      expect(find.text('Finding a Hero rider for your order'), findsOneWidget);
      expect(find.text('Calculating…'), findsOneWidget);
      expect(find.text('Ali'), findsNothing);

      await send(
        tester,
        fixAt(
          at(0, -100),
          second: 1,
          state: CourierFixState.toStore,
          etaSeconds: 600,
        ),
      );
      expect(find.bySemanticsLabel('10 min'), findsOneWidget);
      expect(find.text('Your rider is heading to the store'), findsOneWidget);
      expect(find.text('Ali'), findsOneWidget);
      expect(find.text('Now'), findsOneWidget);

      await send(tester, fixAt(at(0, 300), second: 3, etaSeconds: 150));
      expect(find.text('Your order is on its way to you'), findsOneWidget);
      expect(find.bySemanticsLabel('3 min'), findsOneWidget);

      await send(
        tester,
        fixAt(at(300, 400), second: 5, state: CourierFixState.arrived),
      );
      expect(find.text('Your rider is here'), findsOneWidget);
      expect(
        find.text('Meet your rider at the door to collect your order'),
        findsOneWidget,
      );
      expect(find.text('Now'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('once the rider heads here: message (with unread) and call', (
      tester,
    ) async {
      await pumpPanel(tester, trip: testTrip(riderPhone: '+96522200000'));
      await send(
        tester,
        fixAt(
          at(0, -100),
          second: 1,
          state: CourierFixState.toStore,
          etaSeconds: 600,
        ),
      );
      expect(find.byTooltip('Message your rider'), findsNothing);
      expect(chat.watched, isEmpty);

      await send(tester, fixAt(at(0, 300), second: 3, etaSeconds: 150));
      expect(find.byTooltip('Message your rider'), findsOneWidget);
      expect(find.byTooltip('Call your rider'), findsOneWidget);
      expect(chat.watched, ['o1']);

      chat.push(RiderChat(messages: [riderSays('m1', fixTime)]));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(chatCubit.state.unread, 1);
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byTooltip('Message your rider'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Chat with Ali'), findsOneWidget);
      expect(chatCubit.state.unread, 0);

      await tester.tap(find.text('Please leave it at the door'));
      await tester.pump();
      expect(chat.sent.single.$3, RiderQuickReply.leaveAtDoor);

      await tester.tapAt(const Offset(200, 20));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Chat with Ali'), findsNothing);
      expect(chatCubit.state.open, isFalse);

      await tester.tap(find.byTooltip('Call your rider'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Call Ali'), findsOneWidget);
      expect(find.text('Call now'), findsOneWidget);
      expect(find.textContaining('ending in 0000'), findsOneWidget);
      expect(find.text('Your driver'), findsWidgets);

      await tester.tap(find.text('Message instead'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Call Ali'), findsNothing);
      expect(find.text('Chat with Ali'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(cubit.close);
    });

    testWidgets('no line to the rider: message only', (tester) async {
      await pumpPanel(tester);
      await send(tester, fixAt(at(0, 300), second: 3, etaSeconds: 150));

      expect(find.byTooltip('Message your rider'), findsOneWidget);
      expect(find.byTooltip('Call your rider'), findsNothing);
      await tester.runAsync(cubit.close);
    });

    testWidgets('names the vehicle, or a Hero rider when the feed names no '
        'one', (tester) async {
      await pumpPanel(
        tester,
        trip: CourierTrip(
          orderId: 'o1',
          route: CourierRoute([at(0, 0), at(0, 400)]),
          vehicle: CourierVehicle.motorbike,
        ),
      );
      await send(tester, fixAt(at(0, 100), second: 1, etaSeconds: 120));

      expect(find.text('Your Hero rider'), findsOneWidget);
      expect(find.text('Your driver · Motorbike'), findsOneWidget);
      // The rider is still on the way: stop its clock (on the real loop,
      // where the widgets subscribed).
      await tester.runAsync(cubit.close);
    });

    testWidgets('Arabic, 360 dp, text scale 1.3: no overflow', (tester) async {
      await pumpPanel(
        tester,
        locale: _ar,
        textScale: 1.3,
        size: const Size(360, 800),
      );
      await send(
        tester,
        fixAt(
          at(0, -100),
          second: 1,
          state: CourierFixState.toStore,
          etaSeconds: 600,
        ),
      );

      expect(find.text('المندوب في طريقه إلى المتجر'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(cubit.close);
    });
  });

  group('live map screen', () {
    // The native map has no view under a widget test: on a platform the
    // maps plugin does not draw on, it stands in with a line of text.
    testWidgets('the top bar stays put while the ride loads, shows and fails', (
      tester,
    ) async {
      final repository = FakeCourierTrackingRepository();
      final cubit = CourierTrackingCubit(
        getTrip: GetCourierTripUseCase(repository),
        watchCourier: WatchCourierUseCase(repository),
      );
      addTearDown(cubit.close);
      final alerts = buildTrackingAlertsCubit(FakeLocalAlerts());
      addTearDown(alerts.close);
      final chatCubit = buildRiderChatCubit(FakeRiderChatRepository());
      addTearDown(chatCubit.close);
      await _pump(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider<CourierTrackingCubit>.value(value: cubit),
            BlocProvider<TrackingAlertsCubit>.value(value: alerts),
            BlocProvider<RiderChatCubit>.value(value: chatCubit),
          ],
          child: const Scaffold(body: LiveMapBody()),
        ),
        size: const Size(400, 900),
      );

      Future<void> settle() async {
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      }

      expect(find.byType(AppLoader), findsOneWidget);
      final bar = tester.element(find.byType(LiveMapTopBar));

      await cubit.start(_order('picking'));
      await settle();
      expect(find.byType(LiveMapScene), findsOneWidget);
      expect(find.byType(LiveMapTopBar), findsOneWidget);
      expect(tester.element(find.byType(LiveMapTopBar)), same(bar));

      // The feed ends first (a dropped connection): asking again then has
      // no live subscription to cancel, which never settles under the test's
      // fake clock.
      unawaited(repository.feed.close());
      await tester.pump();
      repository.tripFailure = const ServerFailure('The ride is gone');
      await cubit.retry();
      await settle();
      expect(find.byType(FailureView), findsOneWidget);
      expect(find.byType(LiveMapTopBar), findsOneWidget);
      expect(tester.element(find.byType(LiveMapTopBar)), same(bar));
      expect(tester.takeException(), isNull);
      await tester.runAsync(cubit.close);
    }, variant: TargetPlatformVariant.only(TargetPlatform.fuchsia));
  });
}
