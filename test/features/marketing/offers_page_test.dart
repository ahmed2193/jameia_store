// The offers page as a Hero collection page: the store's name over a
// cream hero, the offers as flat cards (reward disc, lime reward chip, a
// clock for an offer ending today, the small print), skeleton / empty /
// error states under the hero, and the "View cart" pill only while the
// basket has items. Offline: the saved offers under the "Updated … ago"
// note, "No connection" when nothing is saved, and a returning connection
// refreshes them. Arabic reads right to left; reduced motion is still.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/core/constants/app_constants.dart';
import 'package:hero_mart/src/core/design/hero_assets.dart';
import 'package:hero_mart/src/core/domain/entities/cart_entity.dart';
import 'package:hero_mart/src/core/domain/entities/cart_totals_entity.dart';
import 'package:hero_mart/src/core/domain/entities/data_snapshot.dart';
import 'package:hero_mart/src/core/domain/entities/offer_entity.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/motion/entrance_cascade_item.dart';
import 'package:hero_mart/src/core/widgets/collection_frame.dart';
import 'package:hero_mart/src/core/widgets/connectivity_scope.dart';
import 'package:hero_mart/src/core/widgets/countdown_chip.dart';
import 'package:hero_mart/src/core/widgets/hero_state_view.dart';
import 'package:hero_mart/src/core/widgets/view_cart_pill.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hero_mart/src/features/cart/presentation/cubit/cart_state.dart';
import 'package:hero_mart/src/features/language/presentation/cubit/localization_cubit.dart';
import 'package:hero_mart/src/features/language/presentation/cubit/localization_state.dart';
import 'package:hero_mart/src/features/marketing/domain/entities/content_page_entity.dart';
import 'package:hero_mart/src/features/marketing/domain/repositories/promotions_repository.dart';
import 'package:hero_mart/src/features/marketing/domain/usecases/watch_offers_usecase.dart';
import 'package:hero_mart/src/features/marketing/presentation/cubit/offers_cubit.dart';
import 'package:hero_mart/src/features/marketing/presentation/pages/offers_page.dart';
import 'package:hero_mart/src/features/marketing/presentation/widgets/offer_reward_chip.dart';
import 'package:hero_mart/src/features/marketing/presentation/widgets/offer_reward_disc.dart';
import 'package:hero_mart/src/features/marketing/presentation/widgets/offer_tile.dart';
import 'package:hero_mart/src/features/marketing/presentation/widgets/offer_title.dart';
import 'package:hero_mart/src/features/marketing/presentation/widgets/offers_cart_bar.dart';
import 'package:hero_mart/src/features/marketing/presentation/widgets/offers_skeleton.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/data/snapshot_test_fakes.dart';

class _MockCartCubit extends MockCubit<CartState> implements CartCubit {}

class _MockLocalizationCubit extends MockCubit<LocalizationState>
    implements LocalizationCubit {}

/// Scripted offers streamed like the cached repository: the [saved] copy
/// first (when set), then [offers]; [gate] holds the next reply open.
class _FakeRepository implements PromotionsRepository {
  Either<Failure, List<OfferEntity>> offers = const Right(<OfferEntity>[]);
  List<OfferEntity>? saved;
  Completer<void>? gate;
  int calls = 0;

  @override
  Stream<DataSnapshot<List<OfferEntity>>> watchOffers({
    bool forceRefresh = false,
  }) {
    calls++;
    return networkRead(_reply(), saved: saved);
  }

  Future<Either<Failure, List<OfferEntity>>> _reply() async {
    final pending = gate;
    if (pending != null) {
      gate = null;
      await pending.future;
    }
    return offers;
  }

  @override
  Stream<DataSnapshot<ContentPageEntity>> watchContentPage(
    ContentPageKind kind, {
    bool forceRefresh = false,
  }) => Stream.error(const NotFoundFailure('missing'));
}

/// The app's translation files plus the keys this page introduced, until
/// they land in `assets/i18n` (a key already there wins).
class _TranslationsWithPendingKeys extends AssetLoader {
  const _TranslationsWithPendingKeys();

  static const Map<String, Map<String, String>> _pending = {
    'en': {
      'chip_save_percent': 'Save {percent}%',
      'chip_save_amount': 'Save {amount}',
      'valid_until': 'Valid until {date}',
    },
    'ar': {
      'chip_save_percent': 'وفّر {percent}٪',
      'chip_save_amount': 'وفّر {amount}',
      'valid_until': 'صالح حتى {date}',
    },
  };

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final json = await const RootBundleAssetLoader().load(path, locale);
    if (json == null) return null;
    final offers = Map<String, dynamic>.of(
      json['offers'] as Map<String, dynamic>? ?? const {},
    );
    _pending[locale.languageCode]?.forEach(
      (key, value) => offers.putIfAbsent(key, () => value),
    );
    return {...json, 'offers': offers};
  }
}

const OfferEntity _freeDelivery = OfferEntity(
  id: 'delivery',
  name: 'Free delivery over 5 KWD',
  description: 'Spend 5 KWD or more to unlock free delivery.',
  triggerType: OfferTriggerType.cartSubtotal,
  minSubtotalFils: 5000,
  rewardType: OfferRewardType.freeDelivery,
);

const OfferEntity _moneyOff = OfferEntity(
  id: 'money',
  name: '',
  triggerType: OfferTriggerType.itemQuantity,
  minQuantity: 3,
  rewardType: OfferRewardType.fixedDiscount,
  amountFils: 1000,
);

/// 10% off over 15 KWD, capped at 3 KWD, ending [endsAt].
OfferEntity _percentOff(DateTime endsAt) => OfferEntity(
  id: 'percent',
  name: '10% off over 15 KWD',
  triggerType: OfferTriggerType.cartSubtotal,
  minSubtotalFils: 15000,
  rewardType: OfferRewardType.percentageDiscount,
  percent: 10,
  maxDiscountFils: 3000,
  endsAt: endsAt,
);

/// [count] plain free-delivery offers named "Offer 0", "Offer 1", …
List<OfferEntity> _manyOffers(int count) => [
  for (var i = 0; i < count; i++)
    OfferEntity(
      id: 'offer-$i',
      name: 'Offer $i',
      description: _freeDelivery.description,
      triggerType: _freeDelivery.triggerType,
      minSubtotalFils: _freeDelivery.minSubtotalFils,
      rewardType: _freeDelivery.rewardType,
    ),
];

/// How visible the card showing [text] is: the product of the fades over it.
double _visibility(WidgetTester tester, String text) => tester
    .widgetList<FadeTransition>(
      find.ancestor(of: find.text(text), matching: find.byType(FadeTransition)),
    )
    .fold(1, (visible, fade) => visible * fade.opacity.value);

/// The offers page's own scroll position.
ScrollPosition _offersScroll(WidgetTester tester) => tester
    .state<ScrollableState>(
      find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    )
    .position;

/// Pulls the offers down far enough to refresh and lets the indicator snap
/// into place and call the refresh.
Future<void> _pullToRefresh(WidgetTester tester) async {
  await tester.fling(find.byType(CustomScrollView), const Offset(0, 400), 1000);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

const CartState _emptyCart = CartState(isRestored: true);
const CartState _basket = CartState(
  isRestored: true,
  cart: CartEntity(itemCount: 3, totals: CartTotalsEntity(subtotalFils: 4250)),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeRepository repository;
  late _MockCartCubit cart;
  late StreamController<CartState> cartStates;
  late _MockLocalizationCubit localization;
  late StreamController<LocalizationState> localeStates;

  /// What the app's connectivity scope says; [nudges] counts the banner
  /// shakes.
  late ValueNotifier<({bool offline, int epoch})> connection;
  late int nudges;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting();
  });

  setUp(() {
    repository = _FakeRepository();
    if (sl.isRegistered<OffersCubit>()) sl.unregister<OffersCubit>();
    sl.registerFactory<OffersCubit>(
      () => OffersCubit(WatchOffersUseCase(repository)),
    );
    connection = ValueNotifier((offline: false, epoch: 0));
    nudges = 0;
    cartStates = StreamController<CartState>.broadcast();
    cart = _MockCartCubit();
    whenListen(cart, cartStates.stream, initialState: _emptyCart);
    localeStates = StreamController<LocalizationState>.broadcast();
    localization = _MockLocalizationCubit();
    whenListen(
      localization,
      localeStates.stream,
      initialState: const LocalizationState(locale: Locale('en')),
    );
  });

  tearDown(() async {
    sl.unregister<OffersCubit>();
    await cartStates.close();
    await localeStates.close();
    connection.dispose();
  });

  GoRouter buildRouter() => GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(
        path: '/start',
        builder: (_, _) => const Scaffold(body: Text('start')),
      ),
      GoRoute(path: Routes.offers, builder: (_, _) => const OffersPage()),
      GoRoute(
        path: Routes.search,
        builder: (_, _) => const Scaffold(body: Text('search screen')),
      ),
      GoRoute(
        path: Routes.cartPreview,
        builder: (_, _) => const Scaffold(body: Text('cart screen')),
      ),
    ],
  );

  /// Opens the offers page on top of a start screen. Leaves the first
  /// frames unsettled when [settle] is false (skeleton, reduced motion).
  Future<void> pumpOffers(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    bool reducedMotion = false,
    bool settle = true,
    Size screen = const Size(540, 1200),
  }) async {
    tester.view.physicalSize = screen * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final router = buildRouter();
    addTearDown(router.dispose);
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          path: 'assets/i18n',
          assetLoader: const _TranslationsWithPendingKeys(),
          fallbackLocale: const Locale('en'),
          startLocale: locale,
          saveLocale: false,
          child: MultiBlocProvider(
            providers: [
              BlocProvider<CartCubit>.value(value: cart),
              BlocProvider<LocalizationCubit>.value(value: localization),
            ],
            child: Builder(
              builder: (context) => MaterialApp.router(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                routerConfig: router,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(disableAnimations: reducedMotion),
                  child: ValueListenableBuilder(
                    valueListenable: connection,
                    builder: (context, now, _) => ConnectivityScope(
                      isOffline: now.offline,
                      reconnectEpoch: now.epoch,
                      onNudge: () => nudges++,
                      child: child!,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      // Lets the translations (and the fallback's) load for real.
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
    unawaited(router.push(Routes.offers));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump();
    }
  }

  /// Unmounts the page and lets its delayed entrances run out.
  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  }

  group('OffersPage', () {
    testWidgets('the frame: store name, hero, back and search', (tester) async {
      await pumpOffers(tester);

      expect(find.byType(CollectionFrame), findsOneWidget);
      expect(find.text('Hero'), findsOneWidget);
      expect(
        find.textContaining('Offers for you', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.text('Deals that apply to your basket automatically'),
        findsOneWidget,
      );

      await tester.tap(find.bySemanticsLabel('Search'));
      await tester.pumpAndSettle();
      expect(find.text('search screen'), findsOneWidget);

      await closeApp(tester);
    });

    testWidgets('the back button returns to the screen under the page', (
      tester,
    ) async {
      await pumpOffers(tester);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.byType(OffersPage), findsNothing);
      expect(find.text('start'), findsOneWidget);

      await closeApp(tester);
    });

    testWidgets('loaded: flat cards with reward chips and the small print', (
      tester,
    ) async {
      final endingSoon = DateTime.now().add(const Duration(hours: 2));
      final endingLater = DateTime.now().add(const Duration(days: 90));
      repository.offers = Right([
        _percentOff(endingSoon),
        OfferEntity(
          id: _freeDelivery.id,
          name: _freeDelivery.name,
          description: _freeDelivery.description,
          triggerType: _freeDelivery.triggerType,
          minSubtotalFils: _freeDelivery.minSubtotalFils,
          rewardType: _freeDelivery.rewardType,
          endsAt: endingLater,
        ),
        _moneyOff,
      ]);

      await pumpOffers(tester);

      expect(find.byType(OfferTile), findsNWidgets(3));
      expect(find.byType(OfferRewardDisc), findsNWidgets(3));
      expect(find.byType(OfferRewardChip), findsNWidgets(3));
      // Titles: the backend's names, a headline for the nameless one.
      expect(find.text('10% off over 15 KWD'), findsOneWidget);
      expect(find.text('Free delivery over 5 KWD'), findsOneWidget);
      expect(find.text('KD 1.000 off your order'), findsOneWidget);
      expect(
        find.text('Spend 5 KWD or more to unlock free delivery.'),
        findsOneWidget,
      );
      // Reward chips.
      expect(find.text('Save 10%'), findsOneWidget);
      expect(find.text('Free delivery'), findsOneWidget);
      expect(find.text('Save KD 1.000'), findsOneWidget);
      // The small print.
      expect(find.text('On orders over KD 15.000'), findsOneWidget);
      expect(find.text('On orders over KD 5.000'), findsOneWidget);
      expect(find.text('Up to KD 3.000 off'), findsOneWidget);
      expect(find.text('When you buy 3 or more'), findsOneWidget);
      // Ending today counts down; ending in three months shows its day.
      expect(find.byType(CountdownChip), findsOneWidget);
      expect(find.textContaining('Ends in'), findsOneWidget);
      // The page clock reads whole seconds: two hours left shows 02:00:00
      // (or 01:59:59 when a second boundary passed since the fixture).
      expect(find.textContaining(RegExp('02:00:00|01:59:59')), findsOneWidget);
      expect(find.textContaining('Valid until'), findsOneWidget);
      // An empty basket: no pill.
      expect(find.byType(ViewCartPill), findsNothing);

      await closeApp(tester);
    });

    testWidgets('loading: skeleton cards under the hero, then the offers', (
      tester,
    ) async {
      final gate = Completer<void>();
      repository
        ..gate = gate
        ..offers = const Right([_freeDelivery]);

      await pumpOffers(tester, settle: false);

      expect(find.byType(OffersSkeleton), findsOneWidget);
      expect(
        find.textContaining('Offers for you', findRichText: true),
        findsOneWidget,
      );
      expect(find.byType(OfferTile), findsNothing);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(OffersSkeleton), findsNothing);
      expect(find.byType(OfferTile), findsOneWidget);

      await closeApp(tester);
    });

    testWidgets('empty: the empty view under the hero', (tester) async {
      await pumpOffers(tester);

      expect(find.byType(HeroStateView), findsOneWidget);
      expect(
        find.text('No offers right now — check back soon'),
        findsOneWidget,
      );
      expect(find.byType(CollectionFrame), findsOneWidget);

      await closeApp(tester);
    });

    testWidgets('offline, nothing saved: "No connection"; retry loads them', (
      tester,
    ) async {
      repository.offers = const Left(NetworkFailure());

      await pumpOffers(tester);

      expect(find.text('No connection'), findsOneWidget);
      expect(find.byWidgetPredicate(
        (w) => w is HeroStateView && w.art == HeroAssets.stateError,
      ), findsNothing);
      expect(find.byType(CollectionFrame), findsOneWidget);

      repository.offers = const Right([_freeDelivery]);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('No connection'), findsNothing);
      expect(find.text('Free delivery over 5 KWD'), findsOneWidget);
      expect(repository.calls, 2);

      await closeApp(tester);
    });

    testWidgets('a server error: the error view with the reason', (
      tester,
    ) async {
      repository.offers = const Left(ServerFailure('Offers are resting'));

      await pumpOffers(tester);

      expect(find.byWidgetPredicate(
        (w) => w is HeroStateView && w.art == HeroAssets.stateError,
      ), findsOneWidget);
      expect(find.text('Offers are resting'), findsOneWidget);
      expect(find.text('No connection'), findsNothing);

      await closeApp(tester);
    });

    testWidgets(
      'offline with a saved copy: the offers under the "Updated" note, no snack bar',
      (tester) async {
        connection.value = (offline: true, epoch: 0);
        repository
          ..saved = const [_freeDelivery]
          ..offers = const Left(NetworkFailure());

        await pumpOffers(tester);

        expect(find.text('Free delivery over 5 KWD'), findsOneWidget);
        expect(find.textContaining('Updated'), findsOneWidget);
        expect(find.byWidgetPredicate(
        (w) => w is HeroStateView && w.art == HeroAssets.stateError,
      ), findsNothing);
        expect(find.text('No connection'), findsNothing);
        expect(find.byType(SnackBar), findsNothing);
        expect(nudges, 1, reason: 'the banner speaks for a failed read');

        await closeApp(tester);
      },
    );

    testWidgets('the connection coming back refreshes the saved offers', (
      tester,
    ) async {
      connection.value = (offline: true, epoch: 0);
      repository
        ..saved = const [_freeDelivery]
        ..offers = const Left(NetworkFailure());
      await pumpOffers(tester);
      expect(repository.calls, 1);

      repository
        ..saved = null
        ..offers = const Right([_freeDelivery, _moneyOff]);
      connection.value = (offline: false, epoch: 1);
      await tester.pump();
      await tester.pump(AppConstants.reconnectJitter);
      await tester.pumpAndSettle();

      expect(repository.calls, 2);
      expect(find.byType(OfferTile), findsNWidgets(2));
      expect(find.textContaining('Updated'), findsNothing);

      await closeApp(tester);
    });

    testWidgets(
      'cards scrolled into view, or back into view, are there at once',
      (tester) async {
        repository.offers = Right(_manyOffers(12));
        await pumpOffers(tester, screen: const Size(400, 800));
        // Past the opening cascade.
        await tester.pump(const Duration(seconds: 1));
        expect(_visibility(tester, 'Offer 0'), 1);

        final list = _offersScroll(tester);
        list.jumpTo(list.maxScrollExtent);
        await tester.pump();
        // The first card left the list's cache and was dropped; the last ones
        // were built by the scroll and show on their first frame.
        expect(find.text('Offer 0', skipOffstage: false), findsNothing);
        expect(find.text('Offer 11'), findsOneWidget);
        expect(_visibility(tester, 'Offer 11'), 1);

        list.jumpTo(0);
        await tester.pump();
        expect(find.text('Offer 0'), findsOneWidget);
        expect(_visibility(tester, 'Offer 0'), 1);

        await closeApp(tester);
      },
    );

    testWidgets(
      'pull to refresh: a new offer slots in at once, the others keep their cards',
      (tester) async {
        final endingSoon = DateTime.now().add(const Duration(hours: 2));
        repository.offers = Right([_percentOff(endingSoon), _freeDelivery]);
        await pumpOffers(tester);
        await tester.pump(const Duration(seconds: 1));
        final clockBefore = tester.element(find.byType(CountdownChip));

        const fresh = OfferEntity(
          id: 'fresh',
          name: 'Fresh offer',
          triggerType: OfferTriggerType.itemQuantity,
          minQuantity: 2,
          rewardType: OfferRewardType.freeDelivery,
        );
        final gate = Completer<void>();
        repository
          ..gate = gate
          ..offers = Right([fresh, _percentOff(endingSoon), _freeDelivery]);
        await _pullToRefresh(tester);
        expect(repository.calls, 2);

        gate.complete();
        await tester.pump();

        expect(find.byType(OfferTile), findsNWidgets(3));
        expect(_visibility(tester, 'Fresh offer'), 1);
        expect(_visibility(tester, '10% off over 15 KWD'), 1);
        // The moved card is the same card (its clock keeps running).
        expect(tester.element(find.byType(CountdownChip)), same(clockBefore));
        expect(find.byType(SnackBar), findsNothing);

        await tester.pump(const Duration(seconds: 1));
        await closeApp(tester);
      },
    );

    testWidgets(
      'a failed refresh keeps the offers; the stale note says so — no '
      '"No internet" snack before the app knows it is offline',
      (tester) async {
        repository.offers = const Right([_freeDelivery]);
        await pumpOffers(tester);

        repository.offers = const Left(NetworkFailure());
        await _pullToRefresh(tester);
        await tester.pump(const Duration(seconds: 1));

        expect(repository.calls, 2);
        expect(find.text('Free delivery over 5 KWD'), findsOneWidget);
        expect(find.byWidgetPredicate(
        (w) => w is HeroStateView && w.art == HeroAssets.stateError,
      ), findsNothing);
        expect(find.textContaining('Updated'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);

        await closeApp(tester);
      },
    );

    testWidgets('a language switch reloads the offers', (tester) async {
      repository.offers = const Right([_freeDelivery]);
      await pumpOffers(tester);
      expect(repository.calls, 1);

      localeStates.add(const LocalizationState(locale: Locale('ar')));
      await tester.pumpAndSettle();

      expect(repository.calls, 2);

      await closeApp(tester);
    });

    testWidgets('the cart pill shows only while the basket has items', (
      tester,
    ) async {
      repository.offers = const Right([_freeDelivery]);
      await pumpOffers(tester);
      expect(find.byType(ViewCartPill), findsNothing);

      cartStates.add(_basket);
      await tester.pumpAndSettle();
      expect(find.byType(ViewCartPill), findsOneWidget);
      expect(find.text('View cart'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('View cart, 3, KD 4.250')), findsOne);

      cartStates.add(_emptyCart);
      await tester.pumpAndSettle();
      expect(find.byType(ViewCartPill), findsNothing);

      await closeApp(tester);
    });

    testWidgets('the cart pill opens the cart', (tester) async {
      whenListen(cart, cartStates.stream, initialState: _basket);
      await pumpOffers(tester);

      await tester.tap(find.byType(ViewCartPill));
      await tester.pumpAndSettle();

      expect(find.text('cart screen'), findsOneWidget);

      await closeApp(tester);
    });

    testWidgets('Arabic: the page reads right to left', (tester) async {
      repository.offers = Right([
        _percentOff(DateTime.now().add(const Duration(days: 30))),
      ]);

      await pumpOffers(tester, locale: const Locale('ar'));

      final tile = find.byType(OfferTile);
      expect(Directionality.of(tester.element(tile)), TextDirection.rtl);
      expect(find.text('جميعة'), findsOneWidget);
      expect(
        find.textContaining('عروض لك', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('وفّر 10٪'), findsOneWidget);
      expect(find.textContaining('صالح حتى'), findsOneWidget);
      // The reward disc sits on the right, the title to its left.
      final disc = tester.getRect(find.byType(OfferRewardDisc));
      final title = tester.getRect(find.byType(OfferTitle));
      expect(disc.left, greaterThan(title.right));
      expect(tester.takeException(), isNull);

      await closeApp(tester);
    });

    testWidgets('a small phone in Arabic lays long offers out cleanly', (
      tester,
    ) async {
      final long = List.filled(12, 'عرض طويل جدا على السلة').join(' ');
      repository.offers = Right([
        OfferEntity(
          id: 'long',
          name: long,
          description: long,
          triggerType: OfferTriggerType.cartSubtotal,
          minSubtotalFils: 125000,
          rewardType: OfferRewardType.percentageDiscount,
          percent: 15,
          maxDiscountFils: 12500,
          endsAt: DateTime.now().add(const Duration(hours: 5)),
        ),
        _moneyOff,
      ]);
      whenListen(cart, cartStates.stream, initialState: _basket);

      await pumpOffers(
        tester,
        locale: const Locale('ar'),
        screen: const Size(320, 640),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(OfferTile), findsWidgets);
      expect(find.byType(CountdownChip), findsOneWidget);
      expect(find.byType(ViewCartPill), findsOneWidget);

      await closeApp(tester);
    });

    testWidgets('reduced motion: everything is in place on the first frames', (
      tester,
    ) async {
      repository.offers = const Right([_freeDelivery, _moneyOff]);

      await pumpOffers(tester, reducedMotion: true, settle: false);

      expect(find.byType(OfferTile), findsNWidgets(2));
      // The cascade is skipped: no fade over the cards.
      expect(
        find.descendant(
          of: find.byType(EntranceCascadeItem),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
      expect(find.text('Free delivery over 5 KWD'), findsOneWidget);
      expect(find.byType(ViewCartPill), findsNothing);

      // The first item lands: the pill is full size on the very next frame
      // (it would still be folded away with the animation on). A zero
      // duration lets the cart's event through before that frame.
      cartStates.add(_basket);
      await tester.pump(Duration.zero);
      expect(find.byType(ViewCartPill), findsOneWidget);
      final grow = tester.widget<SizeTransition>(
        find
            .ancestor(
              of: find.byType(ViewCartPill),
              matching: find.byType(SizeTransition),
            )
            .first,
      );
      expect(grow.sizeFactor.value, 1);
      expect(
        tester.getSize(find.byType(OffersCartBar)).height,
        greaterThanOrEqualTo(ViewCartPill.height),
      );

      await closeApp(tester);
    });
  });
}
