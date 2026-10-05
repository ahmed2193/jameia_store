// The language switch never splits the app: the context the switch is asked
// from is read once, before the first await. A context already gone
// switches nothing and saves nothing (before: the choice was saved and the
// cubit moved while the screen stayed in the old language — and every later
// tap on that language was dropped as "already chosen"); a context that goes
// while the switch runs no longer matters (before: the screen never switched).
import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hero_mart/src/core/error/failures.dart';
import 'package:hero_mart/src/features/account/presentation/cubit/setting_cubit.dart';
import 'package:hero_mart/src/features/language/domain/repositories/lang_repository.dart';
import 'package:hero_mart/src/features/language/domain/usecases/change_lang_usecase.dart';
import 'package:hero_mart/src/features/language/domain/usecases/get_saved_lang_usecase.dart';
import 'package:hero_mart/src/features/language/domain/usecases/sync_language_usecase.dart';
import 'package:hero_mart/src/features/language/presentation/cubit/localization_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves in memory; [gate] holds a save until completed.
class _Repository implements LangRepository {
  final List<String> saved = [];
  Completer<void>? gate;

  @override
  Future<Either<Failure, String>> getSavedLang() async => const Right('en');

  @override
  Future<Either<Failure, Unit>> changeLang({required String langCode}) async {
    await gate?.future;
    saved.add(langCode);
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> syncLanguage({
    required String langCode,
  }) async => const Right(unit);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Repository repository;
  late LocalizationCubit cubit;
  late ValueNotifier<bool> showPage;
  // A context that stays (the app's), and one of a page that may go.
  late BuildContext app;
  BuildContext? page;
  String? intlBefore;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  setUp(() {
    intlBefore = Intl.defaultLocale;
    repository = _Repository();
    cubit = LocalizationCubit(
      getSavedLang: GetSavedLangUseCase(repository),
      changeLang: ChangeLangUseCase(repository),
      syncLanguage: SyncLanguageUseCase(repository),
    );
    showPage = ValueNotifier<bool>(true);
    page = null;
  });

  tearDown(() async {
    Intl.defaultLocale = intlBefore;
    showPage.dispose();
    await cubit.close();
  });

  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpApp(WidgetTester tester) async {
    rootBundle.clear();
    await tester.runAsync(() async {
      await tester.pumpWidget(
        EasyLocalization(
          supportedLocales: const [Locale('en'), Locale('ar')],
          path: 'assets/i18n',
          fallbackLocale: const Locale('en'),
          startLocale: const Locale('en'),
          saveLocale: false,
          child: BlocProvider<LocalizationCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) {
                app = context;
                return MaterialApp(
                  locale: context.locale,
                  supportedLocales: context.supportedLocales,
                  localizationsDelegates: context.localizationDelegates,
                  home: ValueListenableBuilder<bool>(
                    valueListenable: showPage,
                    builder: (_, show, _) => show
                        ? Builder(
                            builder: (context) {
                              page = context;
                              return const SizedBox();
                            },
                          )
                        : const SizedBox(),
                  ),
                );
              },
            ),
          ),
        ),
      );
    });
    // The strings load for real (slower when the whole suite runs).
    for (var i = 0; i < 200 && page == null; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    expect(page, isNotNull, reason: 'the app built');
    await frames(tester);
  }

  testWidgets('a context already gone switches nothing and saves nothing; '
      'the same choice made again goes through', (tester) async {
    await pumpApp(tester);
    final gone = page!;
    showPage.value = false;
    await tester.pump();

    final result = await cubit.changeLanguageAndWait(gone, 'ar');

    expect(result.success, isFalse);
    expect(cubit.state.languageCode, 'en');
    expect(cubit.state.isLoading, isFalse);
    expect(repository.saved, isEmpty);
    expect(app.locale, const Locale('en'));

    showPage.value = true;
    await tester.pump();
    final again = await tester.runAsync(
      () => cubit.changeLanguageAndWait(page!, 'ar'),
    );
    await frames(tester);

    expect(again!.success, isTrue);
    expect(cubit.state.languageCode, 'ar');
    expect(app.locale, const Locale('ar'));
    expect(repository.saved, ['ar']);
    expect(Intl.defaultLocale, 'ar');
  });

  testWidgets('a context that goes while the switch runs still switches the '
      'whole app', (tester) async {
    await pumpApp(tester);
    repository.gate = Completer<void>();

    // Started in real async: the strings load from the asset bundle.
    late Future<LanguageChangeResult> switching;
    await tester.runAsync(() async {
      switching = cubit.changeLanguageAndWait(page!, 'ar');
    });
    // The page that asked closes while the choice is being saved.
    showPage.value = false;
    await tester.pump();
    final result = await tester.runAsync(() async {
      repository.gate!.complete();
      return switching;
    });
    await frames(tester);

    expect(result!.success, isTrue);
    expect(cubit.state.languageCode, 'ar');
    expect(app.locale, const Locale('ar'), reason: 'the screen switched too');
    expect(Intl.defaultLocale, 'ar');
    expect(repository.saved, ['ar']);
  });

  testWidgets('SettingCubit refuses a context already gone, quietly', (
    tester,
  ) async {
    await pumpApp(tester);
    final settings = SettingCubit();
    addTearDown(settings.close);
    final gone = page!;
    showPage.value = false;
    await tester.pump();

    final switched = await settings.changeLanguage(gone, 'ar');

    expect(switched, isFalse);
    expect(settings.state.isChangingLanguage, isFalse);
    expect(settings.state.failure, isNull);
    expect(cubit.state.languageCode, 'en');
    expect(repository.saved, isEmpty);
  });
}
