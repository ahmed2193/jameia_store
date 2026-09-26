// The way back from a long browse: well down a list a round button pops up
// in the corner and takes the customer back to the top — even where several
// lists share one route (the shell's tabs), and never for a sideways rail.
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/widgets/back_to_top_button.dart';
import 'package:jameia_mart/src/core/widgets/back_to_top_overlay.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double _row = 120;

/// A long list, like a feed or a listing.
class _Feed extends StatelessWidget {
  const _Feed({this.label = 'Row'});

  final String label;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      for (var i = 0; i < 60; i++)
        SizedBox(height: _row, child: Text('$label $i')),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    final enRaw = await rootBundle.loadString('assets/i18n/en.json');
    Localization.load(
      const Locale('en'),
      translations: Translations(json.decode(enRaw) as Map<String, dynamic>),
    );
  });

  Future<void> pumpApp(
    WidgetTester tester,
    Widget body, {
    bool reducedMotion = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(disableAnimations: reducedMotion),
          child: Scaffold(body: body),
        ),
      ),
    ),
  );

  bool shown(WidgetTester tester) =>
      tester.widget<BackToTopButton>(find.byType(BackToTopButton)).shown;

  ScrollPosition listOf(WidgetTester tester, String firstRow) =>
      Scrollable.of(tester.element(find.text(firstRow))).position;

  testWidgets('well down a list it takes the customer back to the top', (
    tester,
  ) async {
    await pumpApp(tester, const BackToTopOverlay(child: _Feed()));
    final list = listOf(tester, 'Row 0');
    expect(shown(tester), isFalse, reason: 'hidden at the top');

    list.jumpTo(_row * 20);
    await tester.pump();
    expect(shown(tester), isTrue);
    // Readable once it has faded in (a fully clear button reads to nobody).
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Back to top'), findsOneWidget);

    await tester.tap(find.byType(BackToTopButton));
    await tester.pumpAndSettle();
    expect(list.pixels, 0);
    expect(shown(tester), isFalse, reason: 'back at the top, it goes');
  });

  testWidgets('it works where lists share the route (the shell tabs)', (
    tester,
  ) async {
    // Every tab of an IndexedStack is built, and every one follows the
    // route's primary scroll controller.
    await pumpApp(
      tester,
      const IndexedStack(
        children: [
          BackToTopOverlay(child: _Feed(label: 'Home')),
          _Feed(label: 'Search'),
        ],
      ),
    );
    final home = listOf(tester, 'Home 0');

    home.jumpTo(_row * 20);
    await tester.pump();
    expect(shown(tester), isTrue);

    await tester.tap(find.byType(BackToTopButton));
    await tester.pumpAndSettle();
    expect(home.pixels, 0);
  });

  testWidgets('a sideways rail inside the list does not call it up', (
    tester,
  ) async {
    await pumpApp(
      tester,
      BackToTopOverlay(
        child: ListView(
          children: [
            SizedBox(
              height: _row,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < 60; i++)
                    SizedBox(width: _row, child: Text('Card $i')),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    listOf(tester, 'Card 0').jumpTo(_row * 30);
    await tester.pump();
    expect(shown(tester), isFalse);
  });

  testWidgets('under reduced motion it jumps straight to the top', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const BackToTopOverlay(child: _Feed()),
      reducedMotion: true,
    );
    final list = listOf(tester, 'Row 0');
    list.jumpTo(_row * 20);
    await tester.pump();

    await tester.tap(find.byType(BackToTopButton));
    await tester.pump();
    expect(list.pixels, 0);
  });
}
