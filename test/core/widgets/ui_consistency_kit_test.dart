// The shared pieces of the app-wide consistency pass: the confirmation
// dialog (its answer, its pop-in, reduced motion), the title bar's slots,
// the sheet header, the paged-list footer, the field shell and the
// "Page not found" fallback.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hero_mart/src/config/routes/placeholder_page.dart';
import 'package:hero_mart/src/config/routes/route_args/shell_arrival.dart';
import 'package:hero_mart/src/config/routes/route_args/shell_tabs.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/core/design/hero_icons.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/navigation/navigation.dart';
import 'package:hero_mart/src/core/widgets/app_button.dart';
import 'package:hero_mart/src/core/widgets/app_loader.dart';
import 'package:hero_mart/src/core/widgets/hero_bar_action.dart';
import 'package:hero_mart/src/core/widgets/hero_close_button.dart';
import 'package:hero_mart/src/core/widgets/hero_confirm_dialog.dart';
import 'package:hero_mart/src/core/widgets/hero_field_shell.dart';
import 'package:hero_mart/src/core/widgets/hero_secondary_button.dart';
import 'package:hero_mart/src/core/widgets/hero_sheet_handle.dart';
import 'package:hero_mart/src/core/widgets/hero_sheet_header.dart';
import 'package:hero_mart/src/core/widgets/hero_state_view.dart';
import 'package:hero_mart/src/core/widgets/hero_title_bar.dart';
import 'package:hero_mart/src/core/widgets/load_more_footer.dart';

Widget _host(Widget child, {bool reduced = false}) => MaterialApp(
  builder: (context, page) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
    child: page!,
  ),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('showHeroConfirmDialog', () {
    Future<Future<bool>> open(
      WidgetTester tester, {
      bool reduced = false,
      bool destructive = false,
    }) async {
      late BuildContext context;
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (inner) {
              context = inner;
              return const SizedBox.shrink();
            },
          ),
          reduced: reduced,
        ),
      );
      final answer = showHeroConfirmDialog(
        context,
        title: 'Delete this address?',
        message: 'You can undo this right after.',
        icon: HeroIcons.trash,
        confirmLabel: 'Delete',
        destructive: destructive,
      );
      await tester.pump();
      return answer;
    }

    testWidgets('the confirm pill answers true', (tester) async {
      final answer = await open(tester);
      await tester.pumpAndSettle();
      expect(find.text('Delete this address?'), findsOneWidget);
      expect(find.text('You can undo this right after.'), findsOneWidget);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(await answer, isTrue);
      expect(find.byType(HeroConfirmDialog), findsNothing);
    });

    testWidgets('cancel answers false', (tester) async {
      final answer = await open(tester);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(HeroSecondaryButton),
          matching: find.byType(Text),
        ),
      );
      await tester.pumpAndSettle();
      expect(await answer, isFalse);
    });

    testWidgets('a tap on the scrim answers false, never null', (tester) async {
      final answer = await open(tester);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      expect(await answer, isFalse);
    });

    testWidgets('a destructive confirm is the deep red pill', (tester) async {
      await open(tester, destructive: true);
      await tester.pumpAndSettle();
      final confirm = tester.widget<AppButton>(
        find.ancestor(
          of: find.text('Delete'),
          matching: find.byType(AppButton),
        ),
      );
      expect(confirm.color, AppColors.errorDeep);
    });

    testWidgets('it pops in from ${AppMotion.dialogPopBegin} on a spring', (
      tester,
    ) async {
      await open(tester);
      final scale = tester.widget<ScaleTransition>(
        find.ancestor(
          of: find.byType(HeroConfirmDialog),
          matching: find.byType(ScaleTransition),
        ),
      );
      expect(scale.scale.value, AppMotion.dialogPopBegin);
      await tester.pumpAndSettle();
      expect(scale.scale.value, 1);
    });

    testWidgets('reduced motion: a fade, no scale', (tester) async {
      await open(tester, reduced: true);
      expect(
        find.ancestor(
          of: find.byType(HeroConfirmDialog),
          matching: find.byType(ScaleTransition),
        ),
        findsNothing,
      );
      await tester.pumpAndSettle();
      expect(find.byType(HeroConfirmDialog), findsOneWidget);
    });
  });

  group('HeroTitleBar slots', () {
    testWidgets('titleLeading sits before the title; actions after', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: HeroTitleBar(
              title: 'Rider',
              titleLeading: const SizedBox.square(
                key: ValueKey<String>('avatar'),
                dimension: 32,
              ),
              actions: [
                HeroBarAction(
                  icon: HeroIcons.phone,
                  tooltip: 'Call',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      final avatar = tester.getRect(
        find.byKey(const ValueKey<String>('avatar')),
      );
      final title = tester.getRect(find.text('Rider'));
      final action = tester.getRect(find.byType(HeroBarAction));
      expect(avatar.right, lessThanOrEqualTo(title.left));
      expect(title.right, lessThanOrEqualTo(action.left));
      expect(find.byTooltip('Call'), findsOneWidget);
    });

    testWidgets('a bottom strip is pinned inside the bar and adds its '
        'height', (tester) async {
      const strip = PreferredSize(
        preferredSize: Size.fromHeight(48),
        child: SizedBox(key: ValueKey<String>('strip'), height: 48),
      );
      const bar = HeroTitleBar(title: 'Fruits', bottom: strip);
      expect(bar.preferredSize.height, HeroTitleBar.height + 48);

      await tester.pumpWidget(const MaterialApp(home: Scaffold(appBar: bar)));
      final barRect = tester.getRect(find.byType(HeroTitleBar));
      final stripRect = tester.getRect(
        find.byKey(const ValueKey<String>('strip')),
      );
      expect(stripRect.bottom, barRect.bottom);
      expect(stripRect.top, greaterThanOrEqualTo(barRect.top));
    });

    testWidgets('a bar action without onPressed is disabled', (tester) async {
      await tester.pumpWidget(
        _host(
          const HeroBarAction(
            icon: HeroIcons.search,
            tooltip: 'Search',
            onPressed: null,
          ),
        ),
      );
      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.onPressed, isNull);
    });
  });

  testWidgets('HeroSheetHeader: handle, title, subtitle, leading and a close '
      'that runs onClose', (tester) async {
    var closed = 0;
    await tester.pumpWidget(
      _host(
        HeroSheetHeader(
          title: 'Sort by',
          subtitle: 'Pick one',
          leading: const SizedBox.square(
            key: ValueKey<String>('lead'),
            dimension: 24,
          ),
          onClose: () => closed++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HeroSheetHandle), findsOneWidget);
    expect(find.text('Sort by'), findsOneWidget);
    expect(find.text('Pick one'), findsOneWidget);
    expect(
      tester.getRect(find.byKey(const ValueKey<String>('lead'))).right,
      lessThanOrEqualTo(tester.getRect(find.text('Sort by')).left),
    );

    await tester.tap(find.byType(HeroCloseButton));
    await tester.pump();
    expect(closed, 1);
  });

  group('LoadMoreFooter', () {
    testWidgets('the dots while loading; a retry pill once it failed', (
      tester,
    ) async {
      var retries = 0;
      Future<void> pump({required bool failed}) => tester.pumpWidget(
        _host(LoadMoreFooter(failed: failed, onRetry: () => retries++)),
      );

      await pump(failed: false);
      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.byType(HeroSecondaryButton), findsNothing);

      await pump(failed: true);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(AppLoader), findsNothing);
      await tester.tap(find.byType(HeroSecondaryButton));
      expect(retries, 1);
    });
  });

  group('HeroFieldShell', () {
    BoxDecoration ring(WidgetTester tester) =>
        tester
                .widget<AnimatedContainer>(
                  find.descendant(
                    of: find.byType(HeroFieldShell),
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .foregroundDecoration!
            as BoxDecoration;

    Color ringColor(WidgetTester tester) =>
        (ring(tester).border! as Border).top.color;

    testWidgets('an ink outline while the field inside has focus', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(width: 300, child: HeroFieldShell(child: TextField())),
        ),
      );
      expect(ringColor(tester), AppColors.scrimTransparent);

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(ringColor(tester), AppColors.primaryText);

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(ringColor(tester), AppColors.scrimTransparent);
    });

    testWidgets('red once refused, focused or not', (tester) async {
      await tester.pumpWidget(
        _host(
          const SizedBox(
            width: 300,
            child: HeroFieldShell(error: true, child: TextField()),
          ),
        ),
      );
      expect(ringColor(tester), AppColors.error);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(ringColor(tester), AppColors.error);
    });
  });

  testWidgets('a location with no screen: the designed not-found state, and '
      'a way home', (tester) async {
    final router = GoRouter(
      initialLocation: '/nowhere',
      routes: [
        GoRoute(
          path: Routes.shell,
          builder: (_, _) => const Scaffold(body: Text('shell')),
        ),
      ],
      errorBuilder: (_, state) =>
          PlaceholderPage(title: PlaceholderPage.titleFor(state.uri.path)),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(HeroStateView), findsOneWidget);
    expect(find.byType(HeroTitleBar), findsOneWidget);
    // No raw path on screen: the words are the localized state's.
    expect(find.textContaining('nowhere'), findsNothing);

    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    expect(find.text('shell'), findsOneWidget);
    expect(router.state.uri.path, Routes.shell);
    expect((router.state.extra! as ShellArrival).tab, ShellTab.home);
  });
}
