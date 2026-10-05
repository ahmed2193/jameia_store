// The language switch in the real app (HeroApp over a scripted backend and
// an in-memory device cache): Settings → العربية under the veil.
//
//   * the tabs stay — same State, same page cubits, the feed kept on screen
//     (never back to the skeleton) — and re-localize in place, const
//     subtrees and the offstage shell included; the feed is read again in
//     the new language, once;
//   * a second switch while the first one's reads are out and failing
//     throws nothing (before: one uncaught exception per cancelled read);
//   * Settings closing while the veil is up still switches the app (before:
//     the switch ran on the closed page's context and was lost).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/app.dart';
import 'package:hero_mart/src/config/di/service_locator.dart';
import 'package:hero_mart/src/config/routes/app_router.dart';
import 'package:hero_mart/src/config/routes/route_args/shell_arrival.dart';
import 'package:hero_mart/src/config/routes/routes.dart';
import 'package:hero_mart/src/core/domain/entities/screen_load.dart';
import 'package:hero_mart/src/core/motion/locale_swap_veil_view.dart';
import 'package:hero_mart/src/core/network/end_points.dart';
import 'package:hero_mart/src/core/storage/json_cache_store.dart';
import 'package:hero_mart/src/features/account/presentation/pages/mine_settings_page.dart';
import 'package:hero_mart/src/features/home/presentation/cubit/home_cubit.dart';
import 'package:hero_mart/src/features/home/presentation/widgets/home_body.dart';
import 'package:hero_mart/src/features/language/domain/usecases/change_lang_usecase.dart';
import 'package:hero_mart/src/features/language/presentation/cubit/localization_cubit.dart';
import 'package:hero_mart/src/features/shell/presentation/pages/main_shell_page.dart';
import 'package:hero_mart/src/features/shell/presentation/widgets/shell_bottom_nav.dart';
import 'package:hero_mart/src/features/shell/presentation/widgets/shell_tab_stack.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/network/network_test_fakes.dart';
import '../../core/storage/cache_test_fakes.dart';

/// The fixture without image URLs (no image cache in a widget test) and
/// without home's popups — no marketing popups, the first-order gift off —
/// so no dialog covers Settings; in Arabic every title is marked, so the two
/// languages' feeds differ.
Object _fixture(String name, {required bool arabic}) {
  Object? clean(Object? value, [String? key]) => switch (value) {
    final Map<String, dynamic> map => {
      for (final entry in map.entries)
        entry.key: switch (entry.key) {
          'popups' => const <Object>[],
          'featureFlags' => {
            ...?clean(entry.value) as Map<String, dynamic>?,
            'firstOrderFreeDelivery': false,
          },
          _ => clean(entry.value, entry.key),
        },
      if (key == 'store' && !map.containsKey('featureFlags'))
        'featureFlags': {'firstOrderFreeDelivery': false},
    },
    final List<dynamic> list => [for (final item in list) clean(item)],
    final String text when text.startsWith('http') => '',
    final String text when arabic && key == 'title' => '$text ع',
    _ => value,
  };
  final raw = File('test/features/home/fixtures/$name').readAsStringSync();
  return clean(jsonDecode(raw))!;
}

/// What the scripted backend saw and how it answers.
class _Backend {
  final List<String> requests = [];
  Duration latency = const Duration(milliseconds: 100);
  bool failing = false;

  FutureOr<ResponseBody> answer(RequestOptions options, int _) async {
    final language = '${options.headers['Accept-Language']}';
    requests.add('${options.path} $language');
    await Future<void>.delayed(latency);
    if (failing) {
      return envelope(
        status: 500,
        statusMessage: 'SERVER_ERROR',
        errorMessage: 'down',
      );
    }
    final arabic = language.startsWith('ar');
    if (options.path.endsWith(EndPoints.home)) {
      return okBody(_fixture('home_en.json', arabic: arabic));
    }
    if (options.path.endsWith(EndPoints.init)) {
      return okBody(_fixture('init_en.json', arabic: arabic));
    }
    return envelope(status: 404, statusMessage: 'NOT_FOUND', errorMessage: '');
  }

  int count(String path, String language) =>
      requests.where((r) => r == '$path $language').length;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final backend = _Backend();
  final en = jsonDecode(File('assets/i18n/en.json').readAsStringSync()) as Map;
  final ar = jsonDecode(File('assets/i18n/ar.json').readAsStringSync()) as Map;
  final searchHintEn = (en['search'] as Map)['store_hint'] as String;
  final searchHintAr = (ar['search'] as Map)['store_hint'] as String;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    await initializeDateFormatting('en');
    await initializeDateFormatting('ar');
    registerFakeNetworkInfo();
    sl.registerSingleton<JsonCacheStore>(InMemoryJsonCacheStore());
    await setupServiceLocator();
    sl<Dio>().httpClientAdapter = FakeHttpClientAdapter(backend.answer);
  });

  setUp(() {
    backend
      ..requests.clear()
      ..latency = const Duration(milliseconds: 100)
      ..failing = false;
  });

  /// Frames with real asset IO between them (the translations load for real).
  Future<void> frames(WidgetTester tester, [int count = 10]) async {
    for (var i = 0; i < count; i++) {
      await tester.pump(const Duration(milliseconds: 60));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
    }
  }

  HomeCubit homeCubit(WidgetTester tester) => tester
      .element(find.byType(HomeBody, skipOffstage: false))
      .read<HomeCubit>();

  String language(WidgetTester tester) => tester
      .element(find.byType(MainShellPage, skipOffstage: false))
      .read<LocalizationCubit>()
      .state
      .languageCode;

  /// [frames] until [done] holds (bounded): the strings load for real, slower
  /// when the whole suite runs.
  Future<void> until(WidgetTester tester, bool Function() done) async {
    for (var i = 0; i < 150 && !done(); i++) {
      await frames(tester, 1);
    }
    await frames(tester, 5);
  }

  /// The app on the shell, in English, with the home feed loaded.
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    rootBundle.clear();
    await tester.runAsync(() async {
      await sl<ChangeLangUseCase>()(const ChangeLangParams('en'));
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          saveLocale: false,
          ignorePluralRules: false,
          child: const HeroApp(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await until(tester, () => find.byType(Navigator).evaluate().isNotEmpty);
    appRouter.go(Routes.shell, extra: ShellArrival());
    await until(
      tester,
      () =>
          find.byType(HomeBody, skipOffstage: false).evaluate().isNotEmpty &&
          homeCubit(tester).state.status == LoadPhase.loaded,
    );
  }

  /// Runs [body] collecting into [uncaught] the errors nobody caught (a
  /// cancelled read's failure, a lost switch); a failed expectation in
  /// [body] still fails the test.
  Future<void> guarded(List<Object> uncaught, Future<void> Function() body) {
    final done = Completer<void>();
    runZonedGuarded(() async {
      try {
        await body();
        done.complete();
      } on Object catch (error, stack) {
        done.completeError(error, stack);
      }
    }, (error, _) => uncaught.add(error));
    return done.future;
  }

  Future<void> teardown(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  }

  Future<void> openSettingsAndPickArabic(WidgetTester tester) async {
    appRouter.push(Routes.mineSettings);
    // On screen, its push transition over (a tap meanwhile is ignored).
    await until(tester, () {
      final page = find.byType(MineSettingsPage).evaluate();
      return page.isNotEmpty &&
          ModalRoute.of(page.first)!.animation!.isCompleted;
    });
    expect(find.byType(MineSettingsPage), findsOneWidget);
    await tester.tap(find.text('العربية'));
  }

  testWidgets('a switch keeps every tab, its state and its feed, and '
      're-localizes it in place', (tester) async {
    await pumpApp(tester);
    final home = homeCubit(tester);
    expect(home.state.status, LoadPhase.loaded);
    final englishFeed = home.state.feed;
    final tabs = tester.state(find.byType(ShellTabStack, skipOffstage: false));
    final phases = <LoadPhase>[];
    final watching = home.stream.listen((state) => phases.add(state.status));
    addTearDown(watching.cancel);
    expect(find.text(searchHintEn, skipOffstage: false), findsOneWidget);
    backend.requests.clear();

    await openSettingsAndPickArabic(tester);
    await until(
      tester,
      () =>
          language(tester) == 'ar' &&
          find.byType(LocaleSwapVeilView).evaluate().isEmpty &&
          home.state.feed != englishFeed,
    );

    expect(language(tester), 'ar');
    expect(find.text('الإعدادات'), findsOneWidget, reason: 'Settings title');
    // The same tabs and page cubit: nothing went back to the skeleton.
    expect(
      tester.state(find.byType(ShellTabStack, skipOffstage: false)),
      same(tabs),
    );
    expect(homeCubit(tester), same(home));
    expect(phases, isNot(contains(LoadPhase.loading)));
    expect(phases, isNot(contains(LoadPhase.initial)));
    // The feed was read again, once, in Arabic — and replaced the English.
    expect(backend.count(EndPoints.home, 'ar'), 1);
    expect(backend.count(EndPoints.home, 'en'), 0);
    expect(home.state.status, LoadPhase.loaded);
    expect(home.state.feed, isNot(englishFeed));
    // Static text re-localized, even const and offstage (shell under
    // Settings, the Search tab hidden in it).
    expect(
      find.descendant(
        of: find.byType(ShellBottomNav, skipOffstage: false),
        matching: find.text(ar['tab_home'] as String, skipOffstage: false),
      ),
      findsOneWidget,
    );
    expect(find.text(searchHintAr, skipOffstage: false), findsOneWidget);
    expect(find.text(searchHintEn, skipOffstage: false), findsNothing);
    expect(tester.takeException(), isNull);

    await teardown(tester);
  });

  testWidgets('a second switch while the reads are out and failing throws '
      'nothing', (tester) async {
    final uncaught = <Object>[];
    await guarded(uncaught, () async {
      await pumpApp(tester);
      backend.latency = const Duration(seconds: 30);
      bool settled(String code) =>
          language(tester) == code &&
          find.byType(LocaleSwapVeilView).evaluate().isEmpty;

      await openSettingsAndPickArabic(tester);
      await until(tester, () => settled('ar'));
      expect(language(tester), 'ar');
      // Arabic reads are still out; the backend goes down; back to English.
      backend.failing = true;
      await tester.tap(find.text('EN'));
      await until(tester, () => settled('en'));
      // The cancelled Arabic reads (and the English ones) fail now.
      await tester.pump(const Duration(seconds: 40));
      await frames(tester, 5);

      expect(language(tester), 'en');
      expect(homeCubit(tester).state.status, LoadPhase.loaded);
      expect(tester.takeException(), isNull);
    });

    expect(uncaught, isEmpty);
    await teardown(tester);
  });

  testWidgets('Settings closing while the veil is up still switches the app', (
    tester,
  ) async {
    final uncaught = <Object>[];
    await guarded(uncaught, () async {
      await pumpApp(tester);

      await openSettingsAndPickArabic(tester);
      // The thumb landed; the veil is fading in. Settings goes at once.
      await tester.pump(const Duration(milliseconds: 250));
      final settings = ModalRoute.of(
        tester.element(find.byType(MineSettingsPage)),
      )!;
      settings.navigator!.removeRoute(settings);
      await tester.pump();
      expect(find.byType(MineSettingsPage), findsNothing);
      await until(
        tester,
        () =>
            language(tester) == 'ar' &&
            find.byType(LocaleSwapVeilView).evaluate().isEmpty,
      );

      expect(language(tester), 'ar');
      expect(
        tester.element(find.byType(MainShellPage, skipOffstage: false)).locale,
        const Locale('ar'),
      );
      expect(find.text(searchHintAr, skipOffstage: false), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    expect(uncaught, isEmpty);
    await teardown(tester);
  });
}
