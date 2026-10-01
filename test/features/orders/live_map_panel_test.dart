// The live map panel's small parts, one by one: the call sheet scrolls on a
// small phone at a large text size (both buttons reachable), the message
// button says how many messages wait, the contact buttons are a full 48 dp
// touch, the ride's stage line is a live region (the rolling minutes are
// not) with the right Arabic plural, and the store → door bar glides at an
// even pace over the time between two fixes, in step with the map rider.
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/core/data/mappers/order_mapper.dart';
import 'package:hero_mart/src/core/data/models/order_model.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/motion/press_scale.dart';
import 'package:hero_mart/src/core/motion/rolling_number_text.dart';
import 'package:hero_mart/src/core/navigation/navigation.dart';
import 'package:hero_mart/src/core/widgets/hero_sheet_header.dart';
import 'package:hero_mart/src/features/orders/domain/entities/courier_fix.dart';
import 'package:hero_mart/src/features/orders/domain/entities/rider_chat.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/get_courier_trip_usecase.dart';
import 'package:hero_mart/src/features/orders/domain/usecases/watch_courier_usecase.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/courier_tracking_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/cubit/rider_chat_cubit.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_call_sheet.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_contact_actions.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_contact_button.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_eta.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_track.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_track_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'courier_test_fakes.dart';
import 'live_map_test_fakes.dart';
import 'order_test_fixtures.dart';

const Locale _en = Locale('en');
const Locale _ar = Locale('ar');

Future<void> _pump(
  WidgetTester tester,
  Widget home, {
  Locale locale = _en,
  double textScale = 1,
  Size size = const Size(400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  // A router like the app's: the sheets close through `context.pop`.
  final router = GoRouter(
    routes: <RouteBase>[GoRoute(path: '/', builder: (_, _) => home)],
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
        // As the app (main.dart): the language's own plural rules.
        ignorePluralRules: false,
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

/// Whether [finder] sits under a `Semantics(liveRegion: true)`.
Finder _inLiveRegion(Finder finder) => find.ancestor(
  of: finder,
  matching: find.byWidgetPredicate(
    (widget) => widget is Semantics && (widget.properties.liveRegion ?? false),
  ),
);

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  group('call sheet', () {
    testWidgets('360 x 640 at text scale 1.3: scrolls, no overflow, '
        '"Message instead" answers true', (tester) async {
      bool? answer;
      final home = Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                answer = await showHeroBottomSheet<bool>(
                  context,
                  backgroundColor: Colors.white,
                  shape: HeroSheetHeader.shape,
                  builder: (_) => LiveMapCallSheet(
                    trip: testTrip(riderPhone: '+96522200000'),
                    rider: 'Ali',
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await _pump(tester, home, textScale: 1.3, size: const Size(360, 640));

      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Call Ali'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(LiveMapCallSheet),
          matching: find.byType(SingleChildScrollView),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);

      final instead = find.text('Message instead');
      await tester.scrollUntilVisible(
        instead,
        40,
        scrollable: find
            .descendant(
              of: find.byType(LiveMapCallSheet),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(instead);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Call Ali'), findsNothing);
      expect(answer, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('contact buttons', () {
    testWidgets('a 48 dp touch around the 44 dp disc', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        Scaffold(
          body: Center(
            child: LiveMapContactButton(
              icon: HeroIcons.chat,
              label: 'Message',
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      final press = find.byType(PressScale);
      expect(tester.getSize(press), const Size(48, 48));

      // Just inside the corner: outside the disc, inside the touch.
      await tester.tapAt(tester.getTopLeft(press) + const Offset(1, 1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(taps, 1);
    });

    testWidgets('the message button says how many messages wait', (
      tester,
    ) async {
      final chat = FakeRiderChatRepository();
      final chatCubit = buildRiderChatCubit(chat);
      addTearDown(chatCubit.close);
      await _pump(
        tester,
        BlocProvider<RiderChatCubit>.value(
          value: chatCubit,
          child: Scaffold(
            body: Center(child: LiveMapContactActions(trip: testTrip())),
          ),
        ),
      );

      expect(find.bySemanticsLabel('Message your rider'), findsOneWidget);

      chat.push(
        RiderChat(
          messages: [
            riderSays('m1', fixTime),
            riderSays('m2', fixTime.add(const Duration(seconds: 5))),
          ],
        ),
      );
      // The chat may have been watched on the real loop (while the page
      // loaded its strings): let its event through there too.
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(chatCubit.state.unread, 2);
      expect(
        find.bySemanticsLabel('Message your rider, 2 new messages'),
        findsOneWidget,
      );
      // The visible name (and its tooltip) stays short.
      expect(find.byTooltip('Message your rider'), findsOneWidget);
    });
  });

  group('ride panel', () {
    late FakeCourierTrackingRepository repository;
    late CourierTrackingCubit cubit;

    Future<void> pumpRide(
      WidgetTester tester,
      Widget child, {
      Locale locale = _en,
    }) async {
      repository = FakeCourierTrackingRepository();
      cubit = CourierTrackingCubit(
        getTrip: GetCourierTripUseCase(repository),
        watchCourier: WatchCourierUseCase(repository),
      );
      addTearDown(cubit.close);
      final json = orderJson(status: 'picking');
      // In the test's own zone: the feed's events then reach the widgets
      // on the next pump.
      await cubit.start(OrderModel.fromJson(json).toEntity());
      await _pump(
        tester,
        BlocProvider<CourierTrackingCubit>.value(
          value: cubit,
          child: Scaffold(body: child),
        ),
        locale: locale,
      );
    }

    Future<void> send(WidgetTester tester, CourierFix fix) async {
      repository.feed.add(fix);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    }

    testWidgets('the stage line is a live region, the minutes are not', (
      tester,
    ) async {
      await pumpRide(tester, const LiveMapEta());
      await send(
        tester,
        fixAt(
          at(0, -100),
          second: 1,
          state: CourierFixState.toStore,
          etaSeconds: 600,
        ),
      );

      final stage = find.text('Your rider is heading to the store');
      expect(stage, findsOneWidget);
      expect(_inLiveRegion(stage), findsOneWidget);
      expect(find.byType(RollingNumberText), findsOneWidget);
      expect(_inLiveRegion(find.byType(RollingNumberText)), findsNothing);
      await tester.runAsync(cubit.close);
    });

    testWidgets('Arabic minutes take the plural form of the number', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpRide(tester, const LiveMapEta(), locale: _ar);
      await send(tester, fixAt(at(0, 300), second: 1, etaSeconds: 300));

      expect(find.bySemanticsLabel(RegExp('دقائق')), findsOneWidget);
      semantics.dispose();
      await tester.runAsync(cubit.close);
    });

    testWidgets('the bar glides over the time between two fixes', (
      tester,
    ) async {
      await pumpRide(tester, const LiveMapTrack());
      double fraction() =>
          tester.widget<LiveMapTrackBar>(find.byType(LiveMapTrackBar)).fraction;

      // Path: 200 m to the store, then 700 m to the door.
      await send(tester, fixAt(at(0, 100), second: 1, etaSeconds: 300));
      expect(fraction(), closeTo(100 / 700, 0.001));

      // 50 m further, 2 s later: after 1 s the bar is half-way there.
      repository.feed.add(fixAt(at(0, 150), second: 3, etaSeconds: 290));
      // The fix reaches the cubit, then the bar takes it as its target.
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(fraction(), closeTo(125 / 700, 0.005));

      await tester.pump(const Duration(seconds: 1));
      expect(fraction(), closeTo(150 / 700, 0.001));
      await tester.runAsync(cubit.close);
    });
  });
}
