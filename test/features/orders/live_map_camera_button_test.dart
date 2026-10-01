// The live map's camera button (LiveMapCameraButton): "See the route"
// while the camera rides along with the rider, "Follow the rider" once the
// customer took the map — nothing while the camera frames the ride by
// itself. Hidden, it takes no taps and reads to nobody; going, it keeps its
// last words.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_camera_action.dart';
import 'package:hero_mart/src/features/orders/presentation/widgets/live_map/live_map_camera_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Locale _en = Locale('en');
const Locale _ar = Locale('ar');

/// The button under [action], in [locale]; every tap lands in [taps].
Future<void> _pump(
  WidgetTester tester,
  ValueNotifier<LiveMapCameraAction?> action,
  List<LiveMapCameraAction> taps, {
  Locale locale = _en,
}) async {
  final host = ValueListenableBuilder<LiveMapCameraAction?>(
    valueListenable: action,
    builder: (context, value, _) =>
        LiveMapCameraButton(action: value, onPressed: taps.add),
  );
  await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const <Locale>[_en, _ar],
        path: 'assets/i18n',
        fallbackLocale: _en,
        startLocale: locale,
        saveLocale: false,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            home: Scaffold(body: Center(child: host)),
          ),
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
  });
  await tester.pump();
  for (
    var i = 0;
    i < 50 && find.byType(LiveMapCameraButton).evaluate().isEmpty;
    i++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  expect(find.byType(LiveMapCameraButton), findsOneWidget);
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('offers the road ahead, then riding along again', (tester) async {
    final action = ValueNotifier<LiveMapCameraAction?>(
      LiveMapCameraAction.overview,
    );
    addTearDown(action.dispose);
    final taps = <LiveMapCameraAction>[];
    await _pump(tester, action, taps);
    await tester.pumpAndSettle();

    expect(find.text('See the route'), findsOneWidget);
    await tester.tap(find.byType(LiveMapCameraButton));
    expect(taps, [LiveMapCameraAction.overview]);

    action.value = LiveMapCameraAction.follow;
    await tester.pumpAndSettle();
    expect(find.text('Follow the rider'), findsOneWidget);
    expect(find.text('See the route'), findsNothing);
    await tester.tap(find.byType(LiveMapCameraButton));
    expect(taps, [LiveMapCameraAction.overview, LiveMapCameraAction.follow]);
  });

  testWidgets('hidden: takes no taps and reads to nobody', (tester) async {
    final semantics = tester.ensureSemantics();
    final action = ValueNotifier<LiveMapCameraAction?>(
      LiveMapCameraAction.follow,
    );
    addTearDown(action.dispose);
    final taps = <LiveMapCameraAction>[];
    await _pump(tester, action, taps);
    await tester.pumpAndSettle();
    expect(find.semantics.byLabel('Follow the rider'), findsOneWidget);

    action.value = null;
    await tester.pump();
    // Going, it keeps its last words…
    expect(find.text('Follow the rider'), findsOneWidget);
    await tester.pumpAndSettle();

    // …and once gone, nothing reads them out or takes a tap.
    expect(find.semantics.byLabel('Follow the rider'), findsNothing);
    await tester.tap(find.byType(LiveMapCameraButton), warnIfMissed: false);
    expect(taps, isEmpty);
    semantics.dispose();
  });

  testWidgets('speaks Arabic', (tester) async {
    final action = ValueNotifier<LiveMapCameraAction?>(
      LiveMapCameraAction.overview,
    );
    addTearDown(action.dispose);
    await _pump(tester, action, <LiveMapCameraAction>[], locale: _ar);
    await tester.pumpAndSettle();

    expect(find.text('عرض الطريق'), findsOneWidget);
    action.value = LiveMapCameraAction.follow;
    await tester.pumpAndSettle();
    expect(find.text('تتبّع المندوب'), findsOneWidget);
  });
}
