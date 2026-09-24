// The announcement strip: it rolls through the store's notices by itself,
// keeps still when it has nothing to roll or the customer asked for less
// motion, and says where it is with its dots.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jameia_mart/src/core/motion/motion.dart';
import 'package:jameia_mart/src/features/home/domain/entities/home_announcement_item.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_announcement_dots.dart';
import 'package:jameia_mart/src/features/home/presentation/widgets/home_announcement_ticker.dart';

const List<HomeAnnouncementItem> _items = [
  HomeAnnouncementItem(id: 'a1', text: 'Free delivery over 5.000 KWD'),
  HomeAnnouncementItem(id: 'a2', text: 'WELCOME10 for 10% off'),
  HomeAnnouncementItem(id: 'a3', text: 'Delivery in 45 min'),
];

void main() {
  Future<void> pump(
    WidgetTester tester,
    List<HomeAnnouncementItem> items, {
    bool reducedMotion = false,
  }) => tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reducedMotion),
      child: MaterialApp(
        home: Scaffold(body: HomeAnnouncementTicker(items: items)),
      ),
    ),
  );

  // Leaves no timer running behind the test.
  Future<void> disposeTicker(WidgetTester tester) =>
      tester.pumpWidget(const SizedBox.shrink());

  testWidgets('rolls to the next notice and moves its dot along', (
    tester,
  ) async {
    await pump(tester, _items);

    expect(find.text(_items.first.text), findsOneWidget);
    expect(
      tester
          .widget<HomeAnnouncementDots>(find.byType(HomeAnnouncementDots))
          .index,
      0,
    );

    await tester.pump(AppMotion.carousel);
    await tester.pumpAndSettle();

    expect(find.text(_items[1].text), findsOneWidget);
    expect(find.text(_items.first.text), findsNothing);
    expect(
      tester
          .widget<HomeAnnouncementDots>(find.byType(HomeAnnouncementDots))
          .index,
      1,
    );

    await disposeTicker(tester);
  });

  testWidgets('a single notice neither rolls nor counts', (tester) async {
    await pump(tester, [_items.first]);

    expect(find.byType(HomeAnnouncementDots), findsOneWidget);
    expect(
      tester.getSize(find.byType(HomeAnnouncementDots)),
      Size.zero,
      reason: 'one notice is not a sequence',
    );

    await tester.pump(AppMotion.carousel);
    expect(find.text(_items.first.text), findsOneWidget);

    await disposeTicker(tester);
  });

  testWidgets('reduced motion holds the first notice', (tester) async {
    await pump(tester, _items, reducedMotion: true);

    await tester.pump(AppMotion.carousel);
    await tester.pump(AppMotion.carousel);

    expect(find.text(_items.first.text), findsOneWidget);

    await disposeTicker(tester);
  });

  testWidgets('no notices, no strip', (tester) async {
    await pump(tester, const []);

    expect(find.byType(HomeAnnouncementDots), findsNothing);
    expect(tester.getSize(find.byType(HomeAnnouncementTicker)), Size.zero);
  });
}
