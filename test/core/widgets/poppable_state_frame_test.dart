// B2-08: a state view of a pushed page with no bar of its own (a recipe or a
// product still loading, or failed) always carries a way back; a root route
// shows none (there is nothing to go back to).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/core/navigation/navigation.dart';
import 'package:hero_mart/src/core/widgets/poppable_state_frame.dart';
import 'package:hero_mart/src/core/widgets/round_back_button.dart';

void main() {
  testWidgets('pushed: a back button that pops; root: none', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: PoppableStateFrame(child: Text('root state')),
          ),
        ),
        GoRoute(
          path: '/loading',
          pageBuilder: (_, state) => HeroTransitionPage<Object?>(
            key: state.pageKey,
            child: const Scaffold(
              body: PoppableStateFrame(child: Text('loading')),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.byType(RoundBackButton), findsNothing);

    router.push('/loading');
    await tester.pumpAndSettle();
    expect(find.byType(RoundBackButton), findsOneWidget);

    await tester.tap(find.byType(RoundBackButton));
    await tester.pumpAndSettle();
    expect(find.text('loading'), findsNothing);
    expect(find.text('root state'), findsOneWidget);
  });
}
