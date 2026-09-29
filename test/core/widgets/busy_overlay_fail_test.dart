// B3-05: a submit held by the busy overlay that comes back failed shows a
// drawn "couldn't finish" × (LoaderFailMark) for a beat — the mark's draw
// plus AppMotion.successHold — before the overlay leaves and the page's
// failure snack is what stays. A failure left over from before never plays.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/widgets/branded_dot_loader.dart';
import 'package:hero_mart/src/core/widgets/busy_overlay.dart';
import 'package:hero_mart/src/core/widgets/cubit_busy_overlay.dart';
import 'package:hero_mart/src/core/widgets/loader_disc.dart';
import 'package:hero_mart/src/core/widgets/loader_fail_mark.dart';

const Duration _tick = Duration(milliseconds: 16);

/// (busy, failed).
class _SubmitCubit extends Cubit<(bool, bool)> {
  _SubmitCubit() : super((false, false));

  void start() => emit((true, false));
  void fail() => emit((false, true));
}

Widget _app(Widget home, {bool reduced = false}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: child!,
  ),
  home: home,
);

void main() {
  late ValueNotifier<(bool, bool)> flags;
  late int taps;

  Future<void> pumpHost(WidgetTester tester, {bool reduced = false}) =>
      tester.pumpWidget(
        _app(
          ValueListenableBuilder<(bool, bool)>(
            valueListenable: flags,
            builder: (_, value, child) => BusyOverlay(
              busy: value.$1,
              failed: value.$2,
              label: 'Saving',
              failLabel: 'Not saved',
              child: child!,
            ),
            child: Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => taps++,
                  child: const Text('under'),
                ),
              ),
            ),
          ),
          reduced: reduced,
        ),
      );

  setUp(() {
    flags = ValueNotifier<(bool, bool)>((false, false));
    taps = 0;
  });

  tearDown(() => flags.dispose());

  testWidgets('a failed submit: the dots turn into the ×, which holds a beat '
      'while taps still wait, then the overlay goes', (tester) async {
    await pumpHost(tester);
    flags.value = (true, false);
    await tester.pump(AppMotion.busyMinVisible);
    flags.value = (false, true);
    await tester.pump();
    // The switch starts its clock on the frame after the flag.
    await tester.pump(AppMotion.page);
    await tester.pump(AppMotion.page);

    expect(find.byType(LoaderFailMark), findsOneWidget);
    expect(find.byType(BrandedDotLoader), findsNothing);
    expect(find.bySemanticsLabel('Not saved'), findsOneWidget);
    await tester.tap(find.text('under'), warnIfMissed: false);
    expect(taps, 0);

    // The beat (draw + hold) runs out, then the scrim fades away.
    await tester.pump(AppMotion.successHold);
    await tester.pump(AppMotion.fast);
    await tester.pump(_tick);
    await tester.pump(_tick);
    expect(find.byType(LoaderDisc), findsNothing);
    await tester.tap(find.text('under'));
    expect(taps, 1);
  });

  testWidgets('the × does not leave before the beat is over', (tester) async {
    await pumpHost(tester);
    flags.value = (true, false);
    await tester.pump(AppMotion.busyMinVisible);
    flags.value = (false, true);
    await tester.pump();
    await tester.pump(AppMotion.slow);
    expect(find.byType(LoaderDisc), findsOneWidget);
    await tester.pump(AppMotion.successHold ~/ 2);
    expect(find.byType(LoaderDisc), findsOneWidget);
  });

  testWidgets('a failure left over from before is not played again', (
    tester,
  ) async {
    await pumpHost(tester);
    // An earlier failure still in the state while idle: nothing shows.
    flags.value = (false, true);
    await tester.pump();
    expect(find.byType(LoaderDisc), findsNothing);

    flags.value = (true, true);
    await tester.pump(AppMotion.busyMinVisible);
    flags.value = (false, true);
    await tester.pump();
    await tester.pump(AppMotion.page);
    expect(find.byType(LoaderFailMark), findsNothing);
  });

  testWidgets('busy again during the beat: back to the dots', (tester) async {
    await pumpHost(tester);
    flags.value = (true, false);
    await tester.pump(AppMotion.busyMinVisible);
    flags.value = (false, true);
    await tester.pump();
    await tester.pump(AppMotion.page);
    flags.value = (true, false);
    await tester.pump();
    await tester.pump(AppMotion.page);
    await tester.pump(AppMotion.page);
    expect(find.byType(LoaderFailMark), findsNothing);
    expect(find.byType(BrandedDotLoader), findsOneWidget);
  });

  testWidgets('reduced motion: the × whole at once, held successHold', (
    tester,
  ) async {
    await pumpHost(tester, reduced: true);
    flags.value = (true, false);
    await tester.pump(AppMotion.busyMinVisible);
    flags.value = (false, true);
    await tester.pump();
    await tester.pump(AppMotion.fast);
    await tester.pump(_tick);
    final mark = find.byType(LoaderFailMark);
    expect(mark, findsOneWidget);
    final scale = tester.widget<ScaleTransition>(
      find.descendant(of: mark, matching: find.byType(ScaleTransition)).first,
    );
    expect(scale.scale.value, 1);

    await tester.pump(AppMotion.successHold);
    await tester.pump(_tick);
    await tester.pump(_tick);
    expect(find.byType(LoaderDisc), findsNothing);
  });

  testWidgets('CubitBusyOverlay: failOf plays the × for the held submit', (
    tester,
  ) async {
    final cubit = _SubmitCubit();
    addTearDown(cubit.close);
    await tester.pumpWidget(
      _app(
        BlocProvider.value(
          value: cubit,
          child: CubitBusyOverlay<_SubmitCubit, (bool, bool)>(
            busyOf: (state) => state.$1,
            failOf: (state) => state.$2,
            label: 'Saving',
            failLabel: 'Not saved',
            child: const Scaffold(body: Text('page')),
          ),
        ),
      ),
    );
    cubit.start();
    await tester.pump();
    await tester.pump(AppMotion.busyMinVisible);
    cubit.fail();
    await tester.pump();
    await tester.pump(AppMotion.page);
    await tester.pump(AppMotion.page);
    expect(find.byType(LoaderFailMark), findsOneWidget);
  });
}
