// The shell's tab switch (docs/motion B1-10): the incoming tab fades in over
// `fast`, every tab keeps its State, hidden tabs tick nothing, reduced motion
// is instant, and tapping a tab plays no haptic.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/features/shell/presentation/widgets/shell_nav_item.dart';
import 'package:hero_mart/src/features/shell/presentation/widgets/shell_tab_stack.dart';

/// A tab that counts its taps in its State, so the test sees it survive.
class _Tab extends StatefulWidget {
  const _Tab(this.name);

  final String name;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => taps++),
    child: Text('${widget.name} $taps'),
  );
}

Widget _stack(int index) => MaterialApp(
  home: Scaffold(
    body: ShellTabStack(
      index: index,
      children: const [_Tab('home'), _Tab('search'), _Tab('mine')],
    ),
  ),
);

double _opacityOf(WidgetTester tester, String text) => tester
    .widgetList<FadeTransition>(
      find.ancestor(
        of: find.textContaining(text),
        matching: find.byType(FadeTransition),
      ),
    )
    .map((f) => f.opacity.value)
    .reduce((a, b) => a * b);

bool _tickersOn(WidgetTester tester, String text) =>
    TickerMode.valuesOf(tester.element(find.textContaining(text))).enabled;

void main() {
  testWidgets('the incoming tab fades in over fast; states are kept', (
    tester,
  ) async {
    await tester.pumpWidget(_stack(0));
    expect(_opacityOf(tester, 'home'), 1);
    await tester.tap(find.text('home 0'));
    await tester.pump();

    await tester.pumpWidget(_stack(1));
    await tester.pump(AppMotion.fast ~/ 3);
    final mid = _opacityOf(tester, 'search');
    expect(mid, greaterThan(0));
    expect(mid, lessThan(1));
    await tester.pump(AppMotion.fast);
    expect(_opacityOf(tester, 'search'), 1);

    // Hidden tabs tick nothing; the one on screen does.
    expect(_tickersOn(tester, 'search'), isTrue);
    expect(
      TickerMode.valuesOf(
        tester.element(find.textContaining('home', skipOffstage: false)),
      ).enabled,
      isFalse,
    );

    await tester.pumpWidget(_stack(0));
    await tester.pumpAndSettle();
    expect(find.text('home 1'), findsOneWidget);
  });

  testWidgets('reduced motion: the switch is instant', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(_stack(0));
    await tester.pumpWidget(_stack(2));
    await tester.pump();
    expect(_opacityOf(tester, 'mine'), 1);
  });

  testWidgets('tapping a tab plays no haptic', (tester) async {
    final haptics = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method.startsWith('HapticFeedback')) haptics.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShellNavItem(
            icon: const Icon(HeroIcons.search),
            label: 'Search',
            selected: false,
            onTap: () => tapped++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();

    expect(tapped, 1);
    expect(haptics, isEmpty);
  });
}
