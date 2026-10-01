import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/data/mappers/order_mapper.dart';
import 'package:hero_mart/src/core/data/models/order_model.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/motion/haptics.dart';
import 'package:hero_mart/src/core/notifications/local_alerts.dart';
import 'package:hero_mart/src/features/orders/data/datasources/tracking_alerts_data_source.dart';
import 'package:hero_mart/src/features/orders/data/repositories/tracking_alerts_repository_impl.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_progress.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_stage.dart';
import 'package:hero_mart/src/features/orders/domain/entities/rider_chat.dart';
import 'package:hero_mart/src/features/orders/domain/entities/tracking_alert.dart';
import 'package:hero_mart/src/features/orders/domain/entities/tracking_alert_rules.dart';
import 'package:hero_mart/src/features/orders/domain/repositories/tracking_alerts_repository.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/allow_tracking_alerts_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/check_tracking_alerts_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/clear_tracking_alert_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/get_courier_trip_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/mark_rider_chat_read_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/send_rider_message_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/show_tracking_alert_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_courier_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_rider_chat_usecase.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/courier_tracking_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/rider_chat_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/tracking_alerts_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_alerts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'courier_test_fakes.dart';
import 'live_map_test_fakes.dart';
import 'order_test_fixtures.dart';

CourierProgress progress({
  CourierStage stage = CourierStage.onTheWay,
  double meters = 500,
  int? minutes = 5,
  Duration after = Duration.zero,
}) => CourierProgress(
  pathMeters: meters,
  deliveryStartMeters: 200,
  pathLengthMeters: 1000,
  stage: stage,
  at: DateTime.utc(2026, 9, 30, 12).add(after),
  minutesLeft: minutes,
);

TrackingAlert alert({
  TrackingAlertKind kind = TrackingAlertKind.ride,
  bool riding = true,
}) => TrackingAlert(
  orderId: 'o1',
  kind: kind,
  channelName: 'Live order tracking',
  title: 'On its way',
  body: 'Ali · 5 min',
  orderLabel: 'Order JM-2004',
  progress: 0.5,
  arrivesAt: DateTime.utc(2026, 9, 30, 12, 5),
  riding: riding,
);

void main() {
  group('TrackingAlertRules', () {
    test('the card changes with the stage, the minute or a step of road', () {
      final shown = progress();

      expect(TrackingAlertRules.cardChanged(null, shown), isTrue);
      expect(TrackingAlertRules.cardChanged(shown, progress()), isFalse);
      expect(
        TrackingAlertRules.cardChanged(shown, progress(meters: 540)),
        isFalse,
      );
      expect(
        TrackingAlertRules.cardChanged(shown, progress(meters: 550)),
        isTrue,
      );
      expect(
        TrackingAlertRules.cardChanged(shown, progress(minutes: 4)),
        isTrue,
      );
      expect(
        TrackingAlertRules.cardChanged(
          shown,
          progress(stage: CourierStage.nearby),
        ),
        isTrue,
      );
    });

    test('a rider held up at the same minute still refreshes the card', () {
      final shown = progress();

      expect(
        TrackingAlertRules.cardChanged(
          shown,
          progress(after: const Duration(seconds: 59)),
        ),
        isFalse,
      );
      expect(
        TrackingAlertRules.cardChanged(
          shown,
          progress(after: TrackingAlertRules.cardRefresh),
        ),
        isTrue,
      );
      // Refreshed well within the time the phone keeps a forgotten card.
      expect(
        TrackingAlertRules.cardRefresh,
        lessThan(PluginLocalAlerts.ongoingGrace),
      );
    });

    test('moments: on the way, almost there, at the door — on a change', () {
      final atStore = progress(stage: CourierStage.atStore);

      for (final stage in [
        CourierStage.onTheWay,
        CourierStage.nearby,
        CourierStage.arrived,
      ]) {
        expect(
          TrackingAlertRules.isMoment(atStore, progress(stage: stage)),
          isTrue,
        );
      }
      expect(
        TrackingAlertRules.isMoment(
          progress(stage: CourierStage.assigning),
          progress(stage: CourierStage.toStore),
        ),
        isFalse,
      );
      // Opening the map mid-ride is no moment.
      expect(TrackingAlertRules.isMoment(null, progress()), isFalse);
      expect(TrackingAlertRules.isMoment(progress(), progress()), isFalse);
    });

    test('the ride fraction covers the whole ride', () {
      expect(progress(meters: 250).rideFraction, 0.25);
      expect(progress(meters: 2000).rideFraction, 1);
    });
  });

  group('TrackingAlertsDataSourceImpl', () {
    test(
      'a ride card: the quiet channel, ongoing, a bar and a countdown',
      () async {
        final shade = FakeLocalAlerts();

        await TrackingAlertsDataSourceImpl(shade).show(alert());

        final card = shade.shown.single;
        expect(card.id, TrackingAlertsDataSourceImpl.rideIdOf('o1'));
        expect(card.channel, LocalAlertChannel.live);
        expect(card.ongoing, isTrue);
        expect(card.progress, 0.5);
        expect(card.dueAt, DateTime.utc(2026, 9, 30, 12, 5));
        expect(card.subText, 'Order JM-2004');
      },
    );

    test('a moment: the loud channel, its own slot, no bar', () async {
      final shade = FakeLocalAlerts();

      await TrackingAlertsDataSourceImpl(shade)
          .show(alert(kind: TrackingAlertKind.moment));

      final moment = shade.shown.single;
      expect(moment.id, TrackingAlertsDataSourceImpl.momentIdOf('o1'));
      expect(moment.id, isNot(TrackingAlertsDataSourceImpl.rideIdOf('o1')));
      expect(moment.channel, LocalAlertChannel.updates);
      expect(moment.ongoing, isFalse);
      expect(moment.progress, isNull);
      expect(moment.dueAt, isNull);
    });

    test(
      'a riding card carries the ride to draw; an ended one does not',
      () async {
        final shade = FakeLocalAlerts();
        final source = TrackingAlertsDataSourceImpl(shade);

        await source.show(alert());
        await source.show(alert(riding: false));

        expect(shade.shown.first.track?.progress, 0.5);
        expect(shade.shown.last.track, isNull);
      },
    );

    test('a rider message: the message channel, its own slot', () async {
      final shade = FakeLocalAlerts();

      await TrackingAlertsDataSourceImpl(shade)
          .show(alert(kind: TrackingAlertKind.message));

      final message = shade.shown.single;
      expect(message.id, TrackingAlertsDataSourceImpl.messageIdOf('o1'));
      expect(message.channel, LocalAlertChannel.messages);
      expect(message.ongoing, isFalse);
      expect(message.track, isNull);
      expect({
        TrackingAlertsDataSourceImpl.rideIdOf('o1'),
        TrackingAlertsDataSourceImpl.momentIdOf('o1'),
        TrackingAlertsDataSourceImpl.messageIdOf('o1'),
      }, hasLength(3));
      // Every id fits a 32-bit notification id.
      expect(
        TrackingAlertsDataSourceImpl.messageIdOf('a-long-order-id-9999'),
        lessThan(0x7FFFFFFF),
      );
    });

    test('clearing takes the ride card away', () async {
      final shade = FakeLocalAlerts();

      await TrackingAlertsDataSourceImpl(shade).clearRide('o1');

      expect(shade.cancelled, [TrackingAlertsDataSourceImpl.rideIdOf('o1')]);
    });
  });

  group('TrackingAlertsCubit', () {
    late FakeLocalAlerts shade;
    late TrackingAlertsRepository repository;

    TrackingAlertsCubit build() => TrackingAlertsCubit(
      check: CheckTrackingAlertsUseCase(repository),
      allow: AllowTrackingAlertsUseCase(repository),
      show: ShowTrackingAlertUseCase(repository),
      clear: ClearTrackingAlertUseCase(repository),
    );

    setUp(() {
      shade = FakeLocalAlerts();
      repository = TrackingAlertsRepositoryImpl(
        TrackingAlertsDataSourceImpl(shade),
      );
    });

    test('posts nothing until it knows the app may', () async {
      final cubit = build();

      await cubit.show(alert());
      expect(shade.shown, isEmpty);

      await cubit.check();
      await cubit.show(alert());
      expect(shade.shown, hasLength(1));
      await cubit.close();
    });

    test('a closed shade shows the prompt; turning on asks once', () async {
      shade.granted = false;
      final cubit = build();

      await cubit.check();
      expect(cubit.state.showPrompt, isTrue);
      expect(shade.asks, 0);

      await cubit.allow();
      expect(shade.asks, 1);
      expect(cubit.state.allowed, isTrue);
      expect(cubit.state.showPrompt, isFalse);
      await cubit.close();
    });

    test('a refusal or a cross puts the prompt away', () async {
      shade
        ..granted = false
        ..onAsk = false;
      final refused = build();
      await refused.check();
      await refused.allow();
      expect(refused.state.allowed, isFalse);
      expect(refused.state.showPrompt, isFalse);

      final dismissed = build();
      await dismissed.check();
      dismissed.dismissPrompt();
      expect(dismissed.state.showPrompt, isFalse);
      await refused.close();
      await dismissed.close();
    });

    test('a ride that ended takes its card away; closing does too', () async {
      final cubit = build();
      await cubit.check();

      await cubit.show(alert());
      await cubit.show(alert(riding: false));
      expect(shade.cancelled, [TrackingAlertsDataSourceImpl.rideIdOf('o1')]);

      await cubit.show(alert());
      await cubit.close();
      await pumpEventQueue();
      expect(shade.cancelled, hasLength(2));
    });

    test('a failing shade reads as closed', () async {
      final failing = _FailingRepository();
      final cubit = TrackingAlertsCubit(
        check: CheckTrackingAlertsUseCase(failing),
        allow: AllowTrackingAlertsUseCase(failing),
        show: ShowTrackingAlertUseCase(failing),
        clear: ClearTrackingAlertUseCase(failing),
      );

      await cubit.check();

      expect(cubit.state.allowed, isFalse);
      await cubit.close();
    });
  });

  group('LiveMapAlerts: the rider\'s messages', () {
    late FakeLocalAlerts shade;
    late FakeRiderChatRepository chat;
    late RiderChatCubit chatCubit;
    late CourierTrackingCubit ride;
    late List<String?> haptics;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
    });

    setUp(Haptics.debugReset);

    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump();
    }

    Future<void> pumpAlerts(WidgetTester tester) async {
      haptics = _recordHaptics(tester);
      if (tester.binding.lifecycleState != AppLifecycleState.resumed) {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
      }
      addTearDown(() => _comeBack(tester));
      final order = OrderModel.fromJson(orderJson(status: 'picking'))
          .toEntity();
      final rides = FakeCourierTrackingRepository();
      ride = CourierTrackingCubit(
        getTrip: GetCourierTripUseCase(rides),
        watchCourier: WatchCourierUseCase(rides),
      );
      addTearDown(ride.close);
      shade = FakeLocalAlerts();
      final alerts = buildTrackingAlertsCubit(shade);
      addTearDown(alerts.close);
      chat = FakeRiderChatRepository();
      chatCubit = RiderChatCubit(
        watch: WatchRiderChatUseCase(chat),
        send: SendRiderMessageUseCase(chat),
        markRead: _IgnoredMarkRead(),
      );
      addTearDown(chatCubit.close);
      await ride.start(order);
      await _pumpLocalized(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider<CourierTrackingCubit>.value(value: ride),
            BlocProvider<TrackingAlertsCubit>.value(value: alerts),
            BlocProvider<RiderChatCubit>.value(value: chatCubit),
          ],
          child: LiveMapAlerts(order: order, child: const SizedBox()),
        ),
      );
      await settle(tester);
      expect(alerts.state.allowed, isTrue);
      chatCubit.start('o1');
    }

    /// The ride's watchdog runs out before the test ends: the binding checks
    /// for pending timers before any tear-down, and a ride with no fixes arms
    /// no other.
    Future<void> finish(WidgetTester tester) => tester.pump(ride.staleAfter);

    Future<void> say(WidgetTester tester, RiderChat now) async {
      chat.push(now);
      await settle(tester);
    }

    Iterable<LocalAlert> messageAlerts() => shade.shown.where(
      (alert) => alert.channel == LocalAlertChannel.messages,
    );

    final t0 = DateTime.utc(2026, 9, 30, 12);
    final m1 = riderSays('m1', t0);
    final m2 = riderSays('m2', t0.add(const Duration(seconds: 1)));
    final m3 = riderSays('m3', t0.add(const Duration(seconds: 2)));

    testWidgets('the greeting the chat opens with buzzes no second time', (
      tester,
    ) async {
      await pumpAlerts(tester);

      await say(tester, RiderChat(messages: [m1]));
      expect(haptics, isEmpty);

      await say(tester, RiderChat(messages: [m1, m2]));
      expect(haptics, hasLength(1));
      expect(messageAlerts(), isEmpty);
      await finish(tester);
    });

    testWidgets('a message read on an earlier open is not announced again', (
      tester,
    ) async {
      await pumpAlerts(tester);
      _goAway(tester);

      await say(tester, RiderChat(messages: [m1, m2], readUpTo: m2.sentAt));
      expect(messageAlerts(), isEmpty);
      expect(chatCubit.state.unread, 0);

      await say(tester, RiderChat(messages: [m1, m2, m3], readUpTo: m2.sentAt));
      expect(messageAlerts(), hasLength(1));
      expect(chatCubit.state.unread, 1);
      await finish(tester);
    });

    testWidgets('the chat left open behind another app still notifies', (
      tester,
    ) async {
      await pumpAlerts(tester);
      await say(tester, RiderChat(messages: [m1]));
      chatCubit.opened();
      await settle(tester);

      // On screen: nothing to tell.
      await say(tester, RiderChat(messages: [m1, m2]));
      expect(haptics, isEmpty);
      expect(messageAlerts(), isEmpty);

      _goAway(tester);
      await say(tester, RiderChat(messages: [m1, m2, m3]));

      expect(messageAlerts(), hasLength(1));
      expect(haptics, isEmpty);
      await finish(tester);
    });
  });
}

/// The customer leaves the app (the lifecycle steps down to paused).
void _goAway(WidgetTester tester) {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

/// Back in the app, if they left it.
void _comeBack(WidgetTester tester) {
  if (tester.binding.lifecycleState != AppLifecycleState.paused) return;
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
  }
}

/// The read marker is not what these tests look at.
class _IgnoredMarkRead implements MarkRiderChatReadUseCase {
  @override
  Future<Either<Failure, Unit>> call(MarkRiderChatReadParams params) async =>
      const Right(unit);
}

/// Every haptic the app asks the platform for.
List<String?> _recordHaptics(WidgetTester tester) {
  final calls = <String?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String?);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

/// [home] in English, once the translations have loaded.
Future<void> _pumpLocalized(WidgetTester tester, Widget home) async {
  const en = Locale('en');
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[en],
        path: 'assets/i18n',
        fallbackLocale: en,
        startLocale: en,
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: home,
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

class _FailingRepository implements TrackingAlertsRepository {
  @override
  Future<Either<Failure, bool>> allowed() async =>
      const Left(UnexpectedFailure());

  @override
  Future<Either<Failure, bool>> ask() async => const Left(UnexpectedFailure());

  @override
  Future<Either<Failure, Unit>> show(TrackingAlert alert) async =>
      const Left(UnexpectedFailure());

  @override
  Future<Either<Failure, Unit>> clearRide(String orderId) async =>
      const Left(UnexpectedFailure());
}
