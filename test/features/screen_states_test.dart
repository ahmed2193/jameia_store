// I7 screen states (docs/motion §9.4 #6, #16-18, #25; Appendix D B1-04,
// B3-01, B3-06, B1-18):
//  * B1-04 — FailureView says "Checking your connection…" before "No
//    connection" and cross-fades between them in place; the shared
//    signed-out state; the "Updated … ago" note over data, never an error.
//  * B3-01 — list first loads show their shaped bones, not the loader disc,
//    and the bones cross-fade into the list.
//  * B3-06 — the brand image placeholder.
//  * B1-18 — a tap on a disabled submit shakes, warns and says why.
import 'dart:async';
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/config/theme/app_colors.dart';
import 'package:hero_mart/src/core/constants/app_constants.dart';
import 'package:hero_mart/src/core/design/hero_assets.dart';
import 'package:hero_mart/src/core/domain/entities/brand_entity.dart';
import 'package:hero_mart/src/core/domain/entities/connection_recheck.dart';
import 'package:hero_mart/src/core/domain/entities/data_freshness.dart';
import 'package:hero_mart/src/core/domain/entities/screen_load.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/core/motion/haptics.dart';
import 'package:hero_mart/src/core/motion/motion.dart';
import 'package:hero_mart/src/core/motion/shake_x.dart';
import 'package:hero_mart/src/core/widgets/connectivity_scope.dart';
import 'package:hero_mart/src/core/widgets/hero_image.dart';
import 'package:hero_mart/src/core/widgets/hero_image_placeholder.dart';
import 'package:hero_mart/src/core/widgets/skeletonized.dart';
import 'package:hero_mart/src/core/widgets/stale_age_pill.dart';
import 'package:hero_mart/src/core/widgets/state_art.dart';
import 'package:hero_mart/src/core/widgets/state_art_loader.dart';
import 'package:hero_mart/src/core/widgets/state_loader_plate.dart';
import 'package:hero_mart/src/core/widgets/state_views.dart';
import 'package:hero_mart/src/features/account/presentation/cubit/delivery_code_cubit.dart';
import 'package:hero_mart/src/features/account/presentation/cubit/loyalty_rewards_cubit.dart';
import 'package:hero_mart/src/features/account/presentation/cubit/loyalty_rewards_state.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/delivery_code/delivery_code_body.dart';
import 'package:hero_mart/src/features/account/presentation/widgets/rewards/rewards_body.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_edit/not_serviceable_banner.dart';
import 'package:hero_mart/src/features/address/presentation/widgets/address_edit/select_sheet.dart';
import 'package:hero_mart/src/features/auth/domain/entities/phone_number.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/otp_cubit.dart';
import 'package:hero_mart/src/features/auth/presentation/cubit/otp_state.dart';
import 'package:hero_mart/src/features/auth/presentation/widgets/otp/otp_body.dart';
import 'package:hero_mart/src/features/auth/presentation/widgets/otp/otp_code_field.dart';
import 'package:hero_mart/src/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:hero_mart/src/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:hero_mart/src/features/notifications/presentation/widgets/notifications_body.dart';
import 'package:hero_mart/src/features/notifications/presentation/widgets/notifications_skeleton.dart';
import 'package:hero_mart/src/features/recipes/presentation/cubit/recipes_cubit.dart';
import 'package:hero_mart/src/features/recipes/presentation/cubit/recipes_state.dart';
import 'package:hero_mart/src/features/recipes/presentation/widgets/recipes_body.dart';
import 'package:hero_mart/src/features/recipes/presentation/widgets/recipes_skeleton.dart';
import 'package:hero_mart/src/features/shop/presentation/cubit/brands_cubit.dart';
import 'package:hero_mart/src/features/shop/presentation/cubit/brands_state.dart';
import 'package:hero_mart/src/features/shop/presentation/widgets/brands/brand_tile.dart';
import 'package:hero_mart/src/features/shop/presentation/widgets/brands/brands_body.dart';
import 'package:hero_mart/src/features/shop/presentation/widgets/brands/brands_skeleton.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockBrandsCubit extends MockCubit<BrandsState> implements BrandsCubit {}

class _MockNotificationsCubit extends MockCubit<NotificationsState>
    implements NotificationsCubit {}

class _MockRecipesCubit extends MockCubit<RecipesState>
    implements RecipesCubit {}

class _MockRewardsCubit extends MockCubit<LoyaltyRewardsState>
    implements LoyaltyRewardsCubit {}

/// A delivery-code screen whose read failed; counts the retries.
class _FailedDeliveryCodeCubit extends Cubit<DeliveryCodeState>
    implements DeliveryCodeCubit {
  _FailedDeliveryCodeCubit()
    : super(
        const DeliveryCodeState(
          status: DeliveryCodeStatus.error,
          failure: CacheFailure('unreadable'),
        ),
      );

  int loads = 0;

  @override
  Future<void> load() async => loads++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockOtpCubit extends MockCubit<OtpState> implements OtpCubit {}

const String _checking = 'Checking your connection…';
const String _noConnection = 'No connection';

const BrandEntity _brand = BrandEntity(id: 'b1', slug: 'acme', name: 'Acme');

/// The haptic kinds that reached the platform, in order.
List<String?> _recordHaptics(WidgetTester tester) {
  final calls = <String?>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String?);
      }
      return null;
    },
  );
  addTearDown(
    () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    ),
  );
  return calls;
}

/// The largest sideways offset [shake] reaches over one shake.
Future<double> _peakShake(WidgetTester tester, Finder shake) async {
  var peak = 0.0;
  for (var i = 0; i < 10; i++) {
    await tester.pump(AppMotion.medium ~/ 10);
    final transform = tester.widget<Transform>(
      find.descendant(of: shake, matching: find.byType(Transform)).first,
    );
    final dx = transform.transform.getTranslation().x.abs();
    if (dx > peak) peak = dx;
  }
  return peak;
}

Finder _art(String asset) => find.byWidgetPredicate(
  (widget) => widget is StateArt && widget.asset == asset,
);

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

  setUp(Haptics.debugReset);

  Widget app(
    Widget body, {
    bool offline = false,
    Future<ConnectionRecheck> Function()? recheck,
  }) => MaterialApp(
    home: ConnectivityScope(
      isOffline: offline,
      reconnectEpoch: 0,
      onNudge: () {},
      recheckForRetry: recheck,
      child: Scaffold(body: body),
    ),
  );

  group('B1-04 state views', () {
    testWidgets('FailureView: "Checking…" first, then "No connection" '
        'cross-fades in place — the dots sit on the art\'s disc', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(
          FailureView(failure: const NetworkFailure(), onRetry: () {}),
          recheck: () async => ConnectionRecheck.offline,
        ),
      );
      await tester.pump();
      expect(find.text(_checking), findsOneWidget);
      expect(find.byType(StateArtLoader), findsOneWidget);
      expect(find.text(_noConnection), findsNothing);

      // The check holds for the offline debounce, then the verdict lands.
      await tester.pump(AppConstants.offlineDebounce);
      await tester.pump(AppMotion.fast ~/ 2);
      expect(find.text(_checking), findsOneWidget, reason: 'fading out');
      expect(find.text(_noConnection), findsOneWidget, reason: 'fading in');
      // The same 88 dp disc, in the same column, in both frames.
      final loader = find.byType(StateArtLoader);
      final art = _art(HeroAssets.stateOffline);
      expect(tester.getSize(loader), tester.getSize(art));
      expect(
        tester.getCenter(find.byType(StateLoaderPlate)) -
            tester.getTopLeft(loader),
        const Offset(80, 58),
      );
      expect(tester.getSize(find.byType(StateLoaderPlate)), const Size(88, 88));
      expect(tester.getCenter(loader).dx, tester.getCenter(art).dx);

      await tester.pumpAndSettle();
      expect(find.text(_checking), findsNothing);
      expect(find.text(_noConnection), findsOneWidget);
      expect(_art(HeroAssets.stateOffline), findsOneWidget);
    });

    testWidgets('the error, sign-in and offline states lead with their art', (
      tester,
    ) async {
      await tester.pumpWidget(app(ErrorView(onRetry: () {})));
      expect(_art(HeroAssets.stateError), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);

      await tester.pumpWidget(
        app(const HeroStateView.signedOut(message: 'Sign in to see this')),
      );
      expect(_art(HeroAssets.stateSignedOut), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);

      await tester.pumpWidget(
        app(
          const EmptyStateView(message: 'Nothing', art: HeroAssets.emptyShelf),
        ),
      );
      expect(_art(HeroAssets.emptyShelf), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('the art fades in from 0.9 once, static under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        app(const StateArt(asset: HeroAssets.emptyShelf)),
      );
      await tester.pump(AppMotion.medium ~/ 2);
      final fade = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(StateArt),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fade.opacity.value, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: app(const StateArt(asset: HeroAssets.emptyAddresses)),
        ),
      );
      final still = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(StateArt),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(still.opacity.value, 1);
    });

    testWidgets('Rewards: a 401 is the shared sign-in state', (tester) async {
      final cubit = _MockRewardsCubit();
      whenListen(
        cubit,
        const Stream<LoyaltyRewardsState>.empty(),
        initialState: const LoyaltyRewardsState(
          status: LoyaltyRewardsStatus.error,
          failure: UnauthorizedFailure(),
        ),
      );
      await tester.pumpWidget(
        app(
          BlocProvider<LoyaltyRewardsCubit>.value(
            value: cubit,
            child: const RewardsBody(),
          ),
        ),
      );
      expect(find.byType(HeroStateView), findsOneWidget);
      expect(_art(HeroAssets.stateSignedOut), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Rewards: a lost connection checks before "No connection"', (
      tester,
    ) async {
      final cubit = _MockRewardsCubit();
      whenListen(
        cubit,
        const Stream<LoyaltyRewardsState>.empty(),
        initialState: const LoyaltyRewardsState(
          status: LoyaltyRewardsStatus.error,
          failure: NetworkFailure(),
        ),
      );
      final never = Completer<ConnectionRecheck>();
      await tester.pumpWidget(
        app(
          BlocProvider<LoyaltyRewardsCubit>.value(
            value: cubit,
            child: const RewardsBody(),
          ),
          recheck: () => never.future,
        ),
      );
      await tester.pump();
      expect(find.byType(FailureView), findsOneWidget);
      expect(find.text(_checking), findsOneWidget);
      expect(find.text(_noConnection), findsNothing);
      // Let the check's debounce run out before the tree goes.
      await tester.pump(AppConstants.offlineDebounce);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Delivery code: a failed read is an error with a retry', (
      tester,
    ) async {
      final cubit = _FailedDeliveryCodeCubit();
      addTearDown(cubit.close);
      await tester.pumpWidget(
        app(
          BlocProvider<DeliveryCodeCubit>.value(
            value: cubit,
            child: const DeliveryCodeBody(),
          ),
        ),
      );
      expect(find.byType(FailureView), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(cubit.loads, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('Brands: the saved list offline carries the "Updated … ago" '
        'note — never an error over data', (tester) async {
      final cubit = _MockBrandsCubit();
      whenListen(
        cubit,
        const Stream<BrandsState>.empty(),
        initialState: BrandsState(
          load: ScreenLoad(
            phase: LoadPhase.loaded,
            freshness: DataFreshness(
              fetchedAt: DateTime.now().subtract(const Duration(minutes: 5)),
              fromCache: true,
            ),
          ),
          brands: const [_brand],
        ),
      );
      await tester.pumpWidget(
        app(
          BlocProvider<BrandsCubit>.value(
            value: cubit,
            child: const BrandsBody(),
          ),
          offline: true,
        ),
      );
      await tester.pump();
      expect(find.byType(StaleAgePill), findsOneWidget);
      expect(find.byType(BrandTile), findsOneWidget);
      expect(find.byType(FailureView), findsNothing);
      expect(find.byType(HeroStateView), findsNothing);
    });
  });

  group('B3-01 shaped skeletons', () {
    testWidgets('Brands, Notifications and Recipes show their bones on a '
        'first load, not the loader disc', (tester) async {
      final brands = _MockBrandsCubit();
      whenListen(
        brands,
        const Stream<BrandsState>.empty(),
        initialState: const BrandsState(
          load: ScreenLoad(phase: LoadPhase.loading),
        ),
      );
      await tester.pumpWidget(
        app(
          BlocProvider<BrandsCubit>.value(
            value: brands,
            child: const BrandsBody(),
          ),
        ),
      );
      expect(find.byType(BrandsSkeleton), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);

      final inbox = _MockNotificationsCubit();
      whenListen(
        inbox,
        const Stream<NotificationsState>.empty(),
        initialState: const NotificationsState(),
      );
      await tester.pumpWidget(
        app(
          BlocProvider<NotificationsCubit>.value(
            value: inbox,
            child: const NotificationsBody(),
          ),
        ),
      );
      expect(find.byType(NotificationsSkeleton), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);

      final recipes = _MockRecipesCubit();
      whenListen(
        recipes,
        const Stream<RecipesState>.empty(),
        initialState: const RecipesState(
          load: ScreenLoad(phase: LoadPhase.loading),
        ),
      );
      await tester.pumpWidget(
        app(
          BlocProvider<RecipesCubit>.value(
            value: recipes,
            child: const RecipesBody(),
          ),
        ),
      );
      expect(find.byType(RecipesSkeleton), findsOneWidget);
      expect(find.byType(AppLoader), findsNothing);
      // The shimmer repaints behind its own boundary, not the page.
      expect(
        find.descendant(
          of: find.byType(Skeletonized),
          matching: find.byType(RepaintBoundary),
        ),
        findsWidgets,
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('the bones cross-fade into the list (fast, no gap)', (
      tester,
    ) async {
      final cubit = _MockBrandsCubit();
      final states = StreamController<BrandsState>();
      addTearDown(states.close);
      whenListen(
        cubit,
        states.stream,
        initialState: const BrandsState(
          load: ScreenLoad(phase: LoadPhase.loading),
        ),
      );
      await tester.pumpWidget(
        app(
          BlocProvider<BrandsCubit>.value(
            value: cubit,
            child: const BrandsBody(),
          ),
        ),
      );
      states.add(
        const BrandsState(
          load: ScreenLoad(phase: LoadPhase.loaded),
          brands: [_brand],
        ),
      );
      await tester.pump();
      await tester.pump(AppMotion.fast ~/ 2);
      expect(find.byType(BrandsSkeleton), findsOneWidget);
      expect(find.byType(BrandTile), findsOneWidget);
      await tester.pump(AppMotion.fast);
      await tester.pump();
      expect(find.byType(BrandsSkeleton), findsNothing);
      expect(find.byType(BrandTile), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  group('B3-06 image placeholder', () {
    testWidgets('the brand placeholder: grey fill + the bag outline, sized '
        'to the box; tiny boxes stay plain', (tester) async {
      final bytes = await tester.runAsync(
        () => rootBundle.load(HeroAssets.imagePlaceholder),
      );
      expect(bytes!.lengthInBytes, greaterThan(0));

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 200,
              height: 100,
              child: HeroImagePlaceholder(),
            ),
          ),
        ),
      );
      final fill = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(HeroImagePlaceholder),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(fill.color, AppColors.smallBackground);
      final glyph = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(
        (glyph.bytesLoader as SvgAssetLoader).assetName,
        HeroAssets.imagePlaceholder,
      );
      expect(glyph.width, 40);
      expect(glyph.excludeFromSemantics, isTrue);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 30,
              height: 30,
              child: HeroImagePlaceholder(),
            ),
          ),
        ),
      );
      expect(find.byType(SvgPicture), findsNothing);
    });

    testWidgets('a product with no photo shows the placeholder, for good', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: HeroImage(url: '', width: 120, height: 120)),
        ),
      );
      expect(find.byType(HeroImagePlaceholder), findsOneWidget);
      expect(find.byIcon(Icons.image_outlined), findsNothing);
    });

    testWidgets('every state plate the screens use ships in the bundle', (
      tester,
    ) async {
      const plates = [
        HeroAssets.stateError,
        HeroAssets.stateOffline,
        HeroAssets.stateSignedOut,
        HeroAssets.stateSearchEmpty,
        HeroAssets.stateUnavailable,
        HeroAssets.stateNotFound,
        HeroAssets.emptyShelf,
        HeroAssets.emptyAddresses,
        HeroAssets.emptyLedger,
        HeroAssets.emptyNotifications,
        HeroAssets.emptyCoupons,
        HeroAssets.emptyBasket,
      ];
      for (final plate in plates) {
        final bytes = await tester.runAsync(() => rootBundle.load(plate));
        expect(bytes!.lengthInBytes, greaterThan(0), reason: plate);
      }
    });
  });

  group('B1-18 disabled submit', () {
    testWidgets('OTP: Verify while the code is short shakes the digits, '
        'warns and says why', (tester) async {
      final haptics = _recordHaptics(tester);
      final cubit = _MockOtpCubit();
      whenListen(
        cubit,
        const Stream<OtpState>.empty(),
        initialState: const OtpState(
          phone: PhoneNumber.kuwait('50000000'),
          code: '12',
          resendSecondsLeft: 30,
        ),
      );
      await tester.pumpWidget(
        app(
          BlocProvider<OtpCubit>.value(
            value: cubit,
            child: const OtpBody(phone: PhoneNumber.kuwait('50000000')),
          ),
        ),
      );
      // The caret blinks for ever: step the clock instead of settling.
      await tester.pump(AppMotion.page);
      expect(find.text('Enter the full code to verify'), findsNothing);

      await tester.tap(find.text('Verify'));
      final shake = find.descendant(
        of: find.byType(OtpCodeField),
        matching: find.byType(ShakeX),
      );
      expect(await _peakShake(tester, shake), greaterThan(0));
      expect(haptics, ['HapticFeedbackType.heavyImpact']);
      await tester.pump(AppMotion.page);
      expect(find.text('Enter the full code to verify'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('Address: Confirm outside the area shakes the reason and '
        'warns, and confirms nothing', (tester) async {
      final haptics = _recordHaptics(tester);
      var confirmed = 0;
      await tester.pumpWidget(
        app(
          SingleChildScrollView(
            child: SelectSheet(
              candidates: const [],
              selected: 0,
              serviceable: false,
              loading: false,
              onSelect: (_) {},
              onConfirm: () => confirmed++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Confirm delivery location'));
      final shake = find.ancestor(
        of: find.byType(NotServiceableBanner),
        matching: find.byType(ShakeX),
      );
      expect(await _peakShake(tester, shake), greaterThan(0));
      expect(haptics, ['HapticFeedbackType.heavyImpact']);
      expect(confirmed, 0);
      await tester.pumpAndSettle();
    });
  });
}
