import 'dart:async';
import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/change_lang_usecase.dart';
import '../../domain/usecases/get_saved_lang_usecase.dart';
import '../../domain/usecases/sync_language_usecase.dart';
import 'localization_state.dart';

/// Outcome of a language change — lets the orchestration layer ([SettingCubit])
/// decide whether to fire the success haptic + post-switch refresh.
class LanguageChangeResult {
  final bool success;
  const LanguageChangeResult({required this.success});
}

/// Central language orchestration — models khayool's `LocalizationCubit`.
///
/// easy_localization stays the engine: `setLocale` loads the strings, rebuilds
/// its dependents and flips the ambient RTL `Directionality`; `.tr()` reads a
/// global, so the app root rebuilds the rest of the tree on this cubit's new
/// locale (`rebuildDescendants`). This cubit owns the pieces around that:
/// launch-time locale restore ([initializeLocale]), the switch entry point
/// ([changeLanguageAndWait]) that persists + applies + mirrors the locale into
/// state, the `Intl.defaultLocale` sync the locale-aware Formatters read, and
/// the best-effort mirror of the choice onto the customer profile
/// ([syncToServer], `PATCH /v1/account/profile { language }`).
///
/// Known debt (§12): it still takes a `BuildContext` for `context.setLocale`.
class LocalizationCubit extends Cubit<LocalizationState> {
  /// Leaves `Intl.defaultLocale` alone: the app root already set it to the
  /// locale easy_localization restored, and a request made before
  /// [initializeLocale] ends (`Accept-Language`) must not go out as `en`.
  LocalizationCubit({
    required this._getSavedLang,
    required this._changeLang,
    required this._syncLanguage,
  }) : super(const LocalizationState(locale: _defaultLocale));

  static const List<Locale> supported = [Locale('en'), Locale('ar')];
  static const Locale _defaultLocale = Locale('en');
  static const String _logName = 'LocalizationCubit';

  final GetSavedLangUseCase _getSavedLang;
  final ChangeLangUseCase _changeLang;
  final SyncLanguageUseCase _syncLanguage;

  /// A sync the network swallowed (offline, a timeout) is owed until one
  /// gets through: [onReconnected] sends it again.
  bool _syncOwed = false;

  /// One-shot launch restore: read the saved language (or the app default),
  /// apply it via easy_localization, sync `Intl`, and mark initialized.
  /// Idempotent — guarded by [LocalizationState.isInitialized].
  Future<void> initializeLocale(BuildContext context) async {
    if (state.isInitialized) return;
    try {
      final savedResult = await _getSavedLang(const NoParams());
      if (isClosed) return;
      // Unreadable prefs fall back to '' (apply the default below).
      final saved = savedResult.fold((_) => '', (code) => code);
      final Locale locale;
      if (saved.isEmpty) {
        // No app-owned choice yet — adopt whatever easy_localization restored
        // (its own saved locale, else `startLocale`) and persist it, so an
        // existing user who picked Arabic under the old code isn't reset.
        locale = context.mounted ? context.locale : _defaultLocale;
        await _changeLang(ChangeLangParams(locale.languageCode));
      } else {
        locale = Locale(saved);
      }
      if (context.mounted) {
        await context.setLocale(locale);
      }
      Intl.defaultLocale = locale.languageCode;
      if (isClosed) return;
      emit(state.copyWith(locale: locale, isInitialized: true));
    } catch (e) {
      log('initializeLocale failed: $e', name: _logName);
      if (!isClosed) emit(state.copyWith(isInitialized: true));
    }
  }

  /// Switch to [code] (`en` / `ar`): persist, apply via easy_localization
  /// (loads the strings, flips RTL), sync `Intl.defaultLocale`, mirror the
  /// new locale into state — the app root then rebuilds the tree so every
  /// `.tr()` resolves again — and push the choice to the account in the
  /// background. The `isLoading` guard drops re-entrant double taps.
  ///
  /// [context] is read once, before the first await: a context already gone
  /// switches nothing and saves nothing (`success: false`), and one that goes
  /// while the switch runs no longer matters. So the state never names a
  /// language the screen does not show.
  Future<LanguageChangeResult> changeLanguageAndWait(
    BuildContext context,
    String code,
  ) async {
    final oldLanguage = state.languageCode;
    if (state.isLoading || code == oldLanguage) {
      return const LanguageChangeResult(success: true);
    }
    final applyLocale = context.mounted
        ? EasyLocalization.of(context)?.setLocale
        : null;
    if (applyLocale == null) {
      log('changeLanguageAndWait($code): no live context', name: _logName);
      return const LanguageChangeResult(success: false);
    }
    emit(state.copyWith(isLoading: true));
    try {
      await _changeLang(ChangeLangParams(code));
      final locale = Locale(code);
      await applyLocale(locale); // loads the strings + persists
      Intl.defaultLocale = code;
      if (isClosed) {
        return const LanguageChangeResult(success: false);
      }
      emit(state.copyWith(locale: locale, isLoading: false));
      unawaited(syncToServer());
      return const LanguageChangeResult(success: true);
    } catch (e) {
      log('changeLanguageAndWait failed: $e', name: _logName);
      if (!isClosed) emit(state.copyWith(isLoading: false));
      return const LanguageChangeResult(success: false);
    }
  }

  /// [syncToServer], but only when the account holds a different language and
  /// only once the launch restore has run: before
  /// [LocalizationState.isInitialized] the state still carries the default
  /// locale, which must never overwrite what the customer chose.
  Future<void> syncIfAccountDiffers(String accountLanguage) async {
    if (!state.isInitialized || accountLanguage == state.languageCode) return;
    await syncToServer();
  }

  /// Mirror the current language onto the customer profile. Signed-out is a
  /// silent no-op; a network failure is logged, never shown — the device
  /// language already changed, and the connection's return
  /// ([onReconnected]), the next sign-in or switch retries.
  Future<void> syncToServer() async {
    final code = state.languageCode;
    final result = await _syncLanguage(SyncLanguageParams(code));
    result.fold((failure) {
      _syncOwed = failure.isTransport;
      log('language sync ($code) skipped: ${failure.message}', name: _logName);
    }, (_) => _syncOwed = false);
  }

  /// The connection came back: a language sync the network swallowed is
  /// sent again (once; another failure waits for the next return).
  Future<void> onReconnected() async {
    if (_syncOwed) await syncToServer();
  }
}
