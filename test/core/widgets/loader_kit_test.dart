// The loader kit: the two Hero dots (BrandedDotPainter's orbit and depth,
// the looping BrandedDotLoader and its still pose under reduced motion), the
// block AppLoader (waits, then springs in) vs AppLoader.inline, BusyOverlay
// (covers the route at once, swallows taps and "back", stays a minimum beat,
// the done check), CubitBusyOverlay (the flag never rebuilds the page) and
// BrandedRefresh (the pull brings the disc down, it loops while refreshing
// and goes once the refresh ends).

import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/app_loader.dart';
import 'package:hero_mart/src/core/widgets/branded_dot_loader.dart';
import 'package:hero_mart/src/core/widgets/branded_dot_painter.dart';
import 'package:hero_mart/src/core/widgets/branded_refresh.dart';
import 'package:hero_mart/src/core/widgets/busy_overlay.dart';
import 'package:hero_mart/src/core/widgets/cubit_busy_overlay.dart';
import 'package:hero_mart/src/core/widgets/delayed_loader_disc.dart';
import 'package:hero_mart/src/core/widgets/loader_disc.dart';
import 'package:hero_mart/src/core/widgets/loader_done_mark.dart';
import 'package:hero_mart/src/core/widgets/refresh_disc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records the ovals a painter draws, in order, with their ARGB colour (a
/// [Paint] keeps its colour in single precision).
class _OvalCanvas implements Canvas {
  final List<(Rect, int)> ovals = [];

  @override
  void drawOval(Rect rect, Paint paint) =>
      ovals.add((rect, paint.color.toARGB32()));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FlagCubit extends Cubit<bool> {
  _FlagCubit() : super(false);

  void set(bool value) => emit(value);
}

/// Counts its builds.
class _Page extends StatelessWidget {
  const _Page(this.onBuild, {required this.onTap});

  final VoidCallback onBuild;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return Center(
      child: TextButton(onPressed: onTap, child: const Text('under')),
    );
  }
}

const int _lead = 0xFF00FF00;
const int _trail = 0xFFFFAA00;

List<(Rect, int)> _paintAt(double phase) {
  final canvas = _OvalCanvas();
  BrandedDotPainter(
    phase: AlwaysStoppedAnimation<double>(phase),
    lead: const Color(_lead),
    trail: const Color(_trail),
  ).paint(canvas, const Size(40, 20));
  return canvas.ovals;
}

Widget _app(Widget home, {bool reduced = false}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: child!,
  ),
  home: home,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final en = json.decode(
      await rootBundle.loadString('assets/i18n/en.json'),
    ) as Map<String, dynamic>;
    Localization.load(const Locale('en'), translations: Translations(en));
  });

  group('BrandedDotPainter', () {
    test('rests side by side, lead first, both the same size', () {
      final ovals = _paintAt(0);
      expect(ovals, hasLength(2));
      final lead = ovals.firstWhere((oval) => oval.$2 == _lead).$1;
      final trail = ovals.firstWhere((oval) => oval.$2 == _trail).$1;
      expect(lead.center.dx, lessThan(trail.center.dx));
      expect(lead.center.dy, trail.center.dy);
      expect(lead.width, moreOrLessEquals(trail.width));
      expect(lead.height, moreOrLessEquals(trail.height));
      expect(lead.width, moreOrLessEquals(lead.height), reason: 'round');
    });

    test('mid-swap the lead passes in front: drawn last, bigger, '
        'stretched along its path', () {
      final ovals = _paintAt(0.25);
      expect(ovals.last.$2, _lead);
      final lead = ovals.last.$1;
      final trail = ovals.first.$1;
      expect(lead.width, greaterThan(trail.width));
      expect(lead.width, greaterThan(lead.height));
      expect(
        ovals.first.$2 >>> 24,
        lessThan(0xFF),
        reason: 'the back dot dims',
      );
      // Crossing the middle: both near the centre line.
      expect((lead.center.dx - 20).abs(), lessThan(2));
      expect((trail.center.dx - 20).abs(), lessThan(2));
    });

    test('the second swap brings the trail dot in front', () {
      final ovals = _paintAt(0.75);
      expect(ovals.last.$2, _trail);
      expect(ovals.last.$1.width, greaterThan(ovals.first.$1.width));
    });

    test('half a loop swaps the dots; a full loop brings them home', () {
      Offset leadAt(double phase) =>
          _paintAt(phase).firstWhere((oval) => oval.$2 == _lead).$1.center;
      expect(leadAt(0.5).dx, greaterThan(leadAt(0).dx));
      expect(leadAt(1).dx, moreOrLessEquals(leadAt(0).dx));
    });
  });

  group('BrandedDotLoader', () {
    testWidgets('loops while shown, half as tall as wide', (tester) async {
      await tester.pumpWidget(
        _app(const Center(child: BrandedDotLoader(size: 32))),
      );
      expect(tester.binding.hasScheduledFrame, isTrue);
      expect(tester.getSize(find.byType(BrandedDotLoader)), const Size(32, 16));
    });

    testWidgets('reduced motion: still, no ticker', (tester) async {
      await tester.pumpWidget(
        _app(const Center(child: BrandedDotLoader(size: 32)), reduced: true),
      );
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
    });
  });

  group('AppLoader', () {
    double discOpacity(WidgetTester tester) => tester
        .widget<FadeTransition>(
          find
              .descendant(
                of: find.byType(DelayedLoaderDisc),
                matching: find.byType(FadeTransition),
              )
              .first,
        )
        .opacity
        .value;

    testWidgets('block: the disc waits a beat, then comes in', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(body: AppLoader())));
      expect(find.byType(LoaderDisc), findsOneWidget);
      expect(discOpacity(tester), 0);
      await tester.pump(AppMotion.loaderDelay);
      expect(discOpacity(tester), 0, reason: 'nothing within the delay');
      await tester.pump(AppMotion.slow);
      expect(discOpacity(tester), 1);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });

    testWidgets('reduced motion: the disc at once', (tester) async {
      await tester.pumpWidget(
        _app(const Scaffold(body: AppLoader()), reduced: true),
      );
      expect(discOpacity(tester), 1);
    });

    testWidgets('inline: the bare dots, no disc', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(body: AppLoader.inline())));
      expect(find.byType(BrandedDotLoader), findsOneWidget);
      expect(find.byType(LoaderDisc), findsNothing);
    });
  });

  group('BusyOverlay', () {
    late ValueNotifier<(bool, bool)> flags;
    late int taps;

    Future<void> pumpHost(WidgetTester tester, {bool reduced = false}) =>
        tester.pumpWidget(
          _app(
            ValueListenableBuilder<(bool, bool)>(
              valueListenable: flags,
              builder: (_, value, child) => BusyOverlay(
                busy: value.$1,
                done: value.$2,
                doneLabel: 'Saved',
                child: child!,
              ),
              child: Scaffold(body: _Page(() {}, onTap: () => taps++)),
            ),
            reduced: reduced,
          ),
        );

    setUp(() {
      flags = ValueNotifier<(bool, bool)>((false, false));
      taps = 0;
    });

    tearDown(() => flags.dispose());

    testWidgets('idle: nothing over the page, taps reach it', (tester) async {
      await pumpHost(tester);
      expect(find.byType(LoaderDisc), findsNothing);
      await tester.tap(find.text('under'));
      expect(taps, 1);
    });

    testWidgets('busy: the scrim and the disc cover the page at once and '
        'swallow taps', (tester) async {
      await pumpHost(tester);
      flags.value = (true, false);
      await tester.pump();
      expect(find.byType(LoaderDisc), findsOneWidget);
      await tester.pump(AppMotion.slow);
      await tester.tap(find.text('under'), warnIfMissed: false);
      expect(taps, 0);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
    });

    testWidgets('a fast reply still shows a beat, then the overlay goes', (
      tester,
    ) async {
      await pumpHost(tester);
      flags.value = (true, false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      flags.value = (false, false);
      await tester.pump();
      expect(find.byType(LoaderDisc), findsOneWidget);
      await tester.pump(AppMotion.busyMinVisible);
      await tester.pump(AppMotion.fast);
      await tester.pump();
      expect(find.byType(LoaderDisc), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse, reason: 'no ticker');
      await tester.tap(find.text('under'));
      expect(taps, 1);
    });

    testWidgets('busy again while it leaves: it stays', (tester) async {
      await pumpHost(tester);
      flags.value = (true, false);
      await tester.pump(AppMotion.busyMinVisible);
      flags.value = (false, false);
      await tester.pump();
      flags.value = (true, false);
      await tester.pump(AppMotion.slow);
      expect(find.byType(LoaderDisc), findsOneWidget);
    });

    testWidgets('done: the dots turn into the check', (tester) async {
      await pumpHost(tester);
      flags.value = (true, false);
      await tester.pump(AppMotion.slow);
      flags.value = (false, true);
      await tester.pump();
      // The switch starts its clock on the frame after the flag.
      await tester.pump(AppMotion.page);
      await tester.pump(AppMotion.page);
      expect(find.byType(LoaderDoneMark), findsOneWidget);
      expect(find.byType(BrandedDotLoader), findsNothing);
      expect(find.bySemanticsLabel('Saved'), findsOneWidget);
    });

    testWidgets('"back" waits while busy', (tester) async {
      await tester.pumpWidget(_app(const Scaffold(body: Text('root'))));
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const BusyOverlay(
              busy: true,
              child: Scaffold(body: Text('page')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(AppMotion.page);
      expect(await navigator.maybePop(), isTrue, reason: 'handled: blocked');
      await tester.pump(AppMotion.page);
      expect(find.text('page'), findsOneWidget);
    });

    testWidgets('reduced motion: it appears whole, dots still', (tester) async {
      await pumpHost(tester, reduced: true);
      flags.value = (true, false);
      await tester.pump();
      await tester.pump();
      final scrim = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byWidgetPredicate(
                (widget) =>
                    widget is ColoredBox && widget.color == AppColors.busyScrim,
              ),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(scrim.opacity.value, 1);
    });
  });

  group('CubitBusyOverlay', () {
    testWidgets('the flag shows the overlay without rebuilding the page', (
      tester,
    ) async {
      final cubit = _FlagCubit();
      addTearDown(cubit.close);
      var builds = 0;
      await tester.pumpWidget(
        _app(
          BlocProvider.value(
            value: cubit,
            child: CubitBusyOverlay<_FlagCubit, bool>(
              busyOf: (busy) => busy,
              child: Scaffold(body: _Page(() => builds++, onTap: () {})),
            ),
          ),
        ),
      );
      final before = builds;
      cubit.set(true);
      await tester.pump();
      expect(find.byType(LoaderDisc), findsOneWidget);
      expect(builds, before);
    });
  });

  group('BrandedRefresh', () {
    testWidgets('a pull brings the disc down; it loops while refreshing '
        'and goes once the refresh ends', (tester) async {
      final refresh = Completer<void>();
      var refreshes = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: BrandedRefresh(
              onRefresh: () {
                refreshes++;
                return refresh.future;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 2000)],
              ),
            ),
          ),
        ),
      );
      expect(find.byType(RefreshDisc), findsNothing);
      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(refreshes, 1);
      expect(find.byType(RefreshDisc), findsOneWidget);
      expect(tester.binding.hasScheduledFrame, isTrue, reason: 'looping');
      refresh.complete();
      await tester.pumpAndSettle();
      expect(find.byType(RefreshDisc), findsNothing);
    });

    testWidgets('a pull let go too early refreshes nothing and the disc '
        'slides back', (tester) async {
      var refreshes = 0;
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: BrandedRefresh(
              onRefresh: () async => refreshes++,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [SizedBox(height: 2000)],
              ),
            ),
          ),
        ),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ListView)),
      );
      await gesture.moveBy(const Offset(0, 20));
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      expect(find.byType(RefreshDisc), findsOneWidget);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(refreshes, 0);
      expect(find.byType(RefreshDisc), findsNothing);
    });
  });
}
