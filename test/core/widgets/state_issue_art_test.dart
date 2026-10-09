// The issue states: what went wrong (StateIssue) picks its own moving plate
// (StateArt + StateArtMotions), title and words; the plates play their story
// within the ambient budget and rest as the still sticker.
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart' hide TextDirection;
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/design/hero_assets.dart';
import 'package:hero_mart/src/core/domain/entities/connection_recheck.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/motion/keyframe_track.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/utils/failure_message.dart';
import 'package:hero_mart/src/core/widgets/connectivity_scope.dart';
import 'package:hero_mart/src/core/widgets/failure_view.dart';
import 'package:hero_mart/src/core/widgets/hero_state_view.dart';
import 'package:hero_mart/src/core/widgets/state_art.dart';
import 'package:hero_mart/src/core/widgets/state_art_layer.dart';
import 'package:hero_mart/src/core/widgets/state_art_motions.dart';
import 'package:hero_mart/src/core/widgets/state_issue.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The [StateArt] drawing [asset].
Finder _plate(String asset) => find.byWidgetPredicate(
  (widget) => widget is StateArt && widget.asset == asset,
);

/// Every part layer's transform, as drawn now.
List<Matrix4> _poses(WidgetTester tester) => [
  for (final transform in tester.widgetList<Transform>(
    find.descendant(
      of: find.byType(StateArtLayer),
      matching: find.byType(Transform),
    ),
  ))
    transform.transform,
];

bool _atRest(List<Matrix4> poses) => poses.every((pose) => pose.isIdentity());

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

  Widget app(Widget child, {bool reduceMotion = false}) => MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: Scaffold(body: child),
      ),
    ),
  );

  group('KeyframeTrack', () {
    const track = KeyframeTrack([
      Keyframe(0.2, 0),
      Keyframe(0.6, 10, AppMotion.linear),
      Keyframe(0.6, 4),
      Keyframe(0.8, 0, AppMotion.linear),
    ]);

    test('holds the first stop before it and the last after it', () {
      expect(track.transform(0), 0);
      expect(track.transform(0.2), 0);
      expect(track.transform(0.9), 0);
      expect(track.transform(1), 0);
    });

    test('eases from stop to stop through the later stop\'s curve; a stop '
        'at the same moment jumps', () {
      expect(track.transform(0.4), closeTo(5, 1e-9));
      expect(track.transform(0.6), 10);
      expect(track.transform(0.7), closeTo(2, 1e-9));
      const eased = KeyframeTrack([
        Keyframe(0, 0),
        Keyframe(1, 1, AppMotion.signature),
      ]);
      expect(eased.transform(0.5), AppMotion.signature.transform(0.5));
    });
  });

  group('StateArtMotions', () {
    test('every issue plate moves; every part is its own drawn layer', () {
      final layers = <String>{};
      for (final issue in StateIssue.values) {
        final parts = StateArtMotions.of(issue.art);
        expect(parts, isNotNull, reason: '${issue.name} has no story');
        for (final part in parts!) {
          expect(layers.add(part.asset), isTrue, reason: part.asset);
          expect(part.asset, isNot(issue.art));
        }
      }
      expect(StateArtMotions.of(HeroAssets.stateUnavailable), isNotNull);
      expect(StateArtMotions.of(HeroAssets.emptyBasket), isNull);
      expect(StateArtMotions.of(HeroAssets.stateSuccess), isNull);
    });

    test('every track ends where it starts: the plate rests as drawn (a '
        'turn may end on a symmetric quarter)', () {
      for (final issue in [
        ...StateIssue.values.map((issue) => issue.art),
        HeroAssets.stateUnavailable,
      ]) {
        for (final part in StateArtMotions.of(issue)!) {
          for (final track in [part.dx, part.dy, part.scale, part.opacity]) {
            if (track == null) continue;
            expect(track.transform(1), track.transform(0), reason: part.asset);
          }
          final turn = part.turn;
          if (turn != null) {
            expect(turn.transform(0), 0, reason: part.asset);
            expect(turn.transform(1) % 90, 0, reason: part.asset);
          }
          // At rest the part is exactly as drawn (or hidden, for a part that
          // only shows mid-story).
          expect(part.transformAt(0, 1).isIdentity(), isTrue);
        }
      }
    });
  });

  group('StateIssue.of', () {
    test('each failure finds its issue', () {
      const cases = <(Failure?, StateIssue)>[
        (NetworkFailure(), StateIssue.offline),
        (TimeoutFailure(), StateIssue.timeout),
        (UnauthorizedFailure(), StateIssue.signedOut),
        (ForbiddenFailure(), StateIssue.forbidden),
        (RateLimitedFailure('slow down'), StateIssue.rateLimited),
        (NotFoundFailure('gone'), StateIssue.notFound),
        (ServerFailure('busy', statusCode: 503), StateIssue.maintenance),
        (ServerFailure('boom', statusCode: 500), StateIssue.server),
        (ServerFailure('bad gateway', statusCode: 502), StateIssue.server),
        (ServerFailure('Out of stock', statusCode: 400), StateIssue.unexpected),
        (ServerFailure('no status'), StateIssue.unexpected),
        (ParsingFailure(), StateIssue.badData),
        (CacheFailure(), StateIssue.unexpected),
        (UnexpectedFailure(), StateIssue.unexpected),
        (null, StateIssue.unexpected),
      ];
      for (final (failure, issue) in cases) {
        expect(StateIssue.of(failure), issue, reason: '$failure');
      }
    });

    test('the store\'s words are its error message, never an empty one', () {
      expect(
        const ServerFailure('Out of stock', statusCode: 400).serverWords,
        'Out of stock',
      );
      expect(const RateLimitedFailure('Wait 60 s').serverWords, 'Wait 60 s');
      // A proxy's error page: no envelope, no words.
      expect(const ServerFailure('', statusCode: 502).serverWords, isNull);
      expect(const ForbiddenFailure('').serverWords, isNull);
      expect(const NetworkFailure().serverWords, isNull);
      expect(
        const ServerFailure('', statusCode: 502).localizedMessage,
        'Something went wrong',
      );
    });
  });

  group('HeroStateView.failure', () {
    Future<void> show(WidgetTester tester, Failure failure) async {
      await tester.pumpWidget(
        app(HeroStateView.failure(failure: failure, onRetry: () {})),
      );
      await tester.pump(AppMotion.page);
    }

    testWidgets('a server error: the smoking server, our words — never the '
        'server\'s own', (tester) async {
      await show(
        tester,
        const ServerFailure(
          "Body cannot be empty when content-type is set to 'application/json'",
          statusCode: 500,
          code: 'INTERNAL_ERROR',
        ),
      );
      expect(_plate(HeroAssets.stateServer), findsOneWidget);
      expect(find.text('Something went wrong on our side'), findsOneWidget);
      expect(
        find.text("We're already on it. Please try again in a moment."),
        findsOneWidget,
      );
      expect(find.textContaining('content-type'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('maintenance, timeout and a payload that could not be read '
        'each lead with their own plate and title', (tester) async {
      await show(tester, const ServerFailure('x', statusCode: 503));
      expect(_plate(HeroAssets.stateMaintenance), findsOneWidget);
      expect(find.text("We'll be right back"), findsOneWidget);

      await show(tester, const TimeoutFailure());
      expect(_plate(HeroAssets.stateTimeout), findsOneWidget);
      expect(find.text('This is taking too long'), findsOneWidget);
      expect(
        find.text('The request timed out. Please try again.'),
        findsOneWidget,
      );

      await show(tester, const ParsingFailure());
      expect(_plate(HeroAssets.stateBadData), findsOneWidget);
      expect(find.text('Something got mixed up'), findsOneWidget);
    });

    testWidgets('a refusal says the store\'s words when it sent some, ours '
        'when it did not', (tester) async {
      await show(tester, const RateLimitedFailure('Try again in 60 seconds'));
      expect(_plate(HeroAssets.stateRateLimited), findsOneWidget);
      expect(find.text('Too many tries'), findsOneWidget);
      expect(find.text('Try again in 60 seconds'), findsOneWidget);

      await show(tester, const ForbiddenFailure(''));
      expect(_plate(HeroAssets.stateForbidden), findsOneWidget);
      expect(find.text('No access'), findsOneWidget);
      expect(
        find.text("This page isn't available for your account."),
        findsOneWidget,
      );
    });

    testWidgets('signed out: the padlock and a sign-in button, no retry', (
      tester,
    ) async {
      await show(tester, const UnauthorizedFailure());
      expect(_plate(HeroAssets.stateSignedOut), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('the generic error never says the same words twice', (
      tester,
    ) async {
      await show(tester, const ServerFailure('Something went wrong'));
      expect(_plate(HeroAssets.stateError), findsOneWidget);
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Please try again in a moment.'), findsOneWidget);

      await tester.pumpWidget(app(HeroStateView.error(onRetry: () {})));
      expect(
        tester.widget<HeroStateView>(find.byType(HeroStateView)).art,
        HeroAssets.stateError,
      );
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Please try again in a moment.'), findsOneWidget);
    });
  });

  group('FailureView', () {
    Future<void> pump(WidgetTester tester, Failure failure) =>
        tester.pumpWidget(
          app(
            ConnectivityScope(
              isOffline: false,
              reconnectEpoch: 0,
              onNudge: () {},
              recheckForRetry: () async => ConnectionRecheck.reachable,
              child: FailureView(failure: failure, onRetry: () {}),
            ),
          ),
        );

    testWidgets('online, a failure that is not the connection is told by '
        'its issue at once — no connection check', (tester) async {
      await pump(tester, const ServerFailure('x', statusCode: 503));
      await tester.pump();
      expect(_plate(HeroAssets.stateMaintenance), findsOneWidget);
      expect(find.text('Checking your connection…'), findsNothing);

      await pump(tester, const TimeoutFailure());
      await tester.pump(AppMotion.page);
      expect(_plate(HeroAssets.stateTimeout), findsOneWidget);
    });

    testWidgets('the screen\'s own words replace the issue\'s', (tester) async {
      await tester.pumpWidget(
        app(
          ConnectivityScope(
            isOffline: false,
            reconnectEpoch: 0,
            onNudge: () {},
            child: FailureView(
              failure: const ServerFailure('x', statusCode: 500),
              message: 'This order cannot be shown',
              onRetry: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(_plate(HeroAssets.stateServer), findsOneWidget);
      expect(find.text('This order cannot be shown'), findsOneWidget);
    });
  });

  group('StateArt', () {
    testWidgets('an issue plate draws its parts over the still plate, plays '
        'its story, then rests as drawn with no frame left', (tester) async {
      await tester.pumpWidget(
        app(const Center(child: StateArt(asset: HeroAssets.stateUnreachable))),
      );
      final pictures = find.descendant(
        of: find.byType(StateArt),
        matching: find.byType(SvgPicture),
      );
      expect(
        pictures,
        findsNWidgets(
          StateArtMotions.of(HeroAssets.stateUnreachable)!.length + 1,
        ),
      );
      expect(_atRest(_poses(tester)), isTrue);

      // A third of the way into the first lap the plug is up at the socket.
      await tester.pump(AppMotion.stateArtLap * 0.3);
      expect(_atRest(_poses(tester)), isFalse);

      // Two laps fit the budget; then it rests, drawing nothing.
      final settled = await tester.pumpAndSettle();
      expect(_atRest(_poses(tester)), isTrue);
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(
        const Duration(milliseconds: 100) * settled,
        lessThanOrEqualTo(AppMotion.ambientBudget + AppMotion.medium),
      );
    });

    testWidgets('reduced motion: the still sticker, parts as drawn and the '
        'mid-story ones hidden', (tester) async {
      await tester.pumpWidget(
        app(
          const Center(child: StateArt(asset: HeroAssets.stateUnreachable)),
          reduceMotion: true,
        ),
      );
      await tester.pump(AppMotion.stateArtLap * 0.3);
      expect(_atRest(_poses(tester)), isTrue);
      final fades = tester.widgetList<FadeTransition>(
        find.descendant(
          of: find.byType(StateArtLayer),
          matching: find.byType(FadeTransition),
        ),
      );
      // The spark only shows while the plug touches the socket.
      expect(fades.map((fade) => fade.opacity.value), [0]);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('a plate with no story is one still picture', (tester) async {
      await tester.pumpWidget(
        app(const Center(child: StateArt(asset: HeroAssets.emptyBasket))),
      );
      expect(
        find.descendant(
          of: find.byType(StateArt),
          matching: find.byType(SvgPicture),
        ),
        findsOneWidget,
      );
      expect(find.byType(StateArtLayer), findsNothing);
    });
  });
}
