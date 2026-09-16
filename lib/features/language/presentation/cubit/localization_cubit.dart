import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/lang_repository.dart';
import 'localization_state.dart';

/// Outcome of a language change — lets the orchestration layer ([SettingCubit])
/// decide whether to fire the success haptic + post-switch refresh.
class LanguageChangeResult {
  final bool success;
  final String? oldLanguage;
  final String? newLanguage;
  const LanguageChangeResult({
    required this.success,
    this.oldLanguage,
    this.newLanguage,
  });
}

/// Central language orchestration — models khayool's `LocalizationCubit` (minus
/// the server sync; this app is offline).
///
/// easy_localization stays the reactive engine: `context.setLocale` rebuilds the
/// whole tree via its InheritedWidget, so every `.tr()` re-resolves and the
/// ambient RTL `Directionality` flips. This cubit owns the pieces around that:
/// launch-time locale restore ([initializeLocale]), the switch entry point
/// ([changeLanguageAndWait]) that persists + applies + mirrors the locale into
/// state, and the `Intl.defaultLocale` sync the locale-aware Formatters read.
///
/// Persistence is now read/written through the feature [LangRepository]
/// directly — the former `ChangeLangUseCase` was a pure pass-through and was
/// collapsed (P2.9 domain rewrite).
class LocalizationCubit extends Cubit<LocalizationState> {
  final LangRepository _repository;

  static const List<Locale> supported = [Locale('en'), Locale('ar')];
  static const Locale _defaultLocale = Locale('en');

  LocalizationCubit({
    required LangRepository repository,
  })  : _repository = repository,
        super(const LocalizationState(locale: _defaultLocale)) {
    Intl.defaultLocale = _defaultLocale.languageCode;
  }

  /// One-shot launch restore: read the saved language (or the app default),
  /// apply it via easy_localization, sync `Intl`, and mark initialized.
  /// Idempotent — guarded by [LocalizationState.isInitialized].
  Future<void> initializeLocale(BuildContext context) async {
    if (state.isInitialized) return;
    try {
      final savedResult = await _repository.getSavedLang();
      if (isClosed) return;
      // Unreadable prefs already fall back to '' inside the repository.
      final saved = savedResult.fold((_) => '', (code) => code);
      final Locale locale;
      if (saved.isEmpty) {
        // No app-owned choice yet — adopt whatever easy_localization restored
        // (its own saved locale, else `startLocale`) and persist it, so an
        // existing user who picked Arabic under the old code isn't reset.
        locale = context.mounted ? context.locale : _defaultLocale;
        await _repository.changeLang(langCode: locale.languageCode);
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
      if (!isClosed) {
        emit(state.copyWith(isInitialized: true, error: e.toString()));
      }
    }
  }

  /// Switch to [code] (`en` / `ar`): persist, apply via easy_localization
  /// (rebuilds every `.tr()` + flips RTL), sync `Intl.defaultLocale`, mirror the
  /// new locale into state. The `isLoading` guard drops re-entrant double taps.
  Future<LanguageChangeResult> changeLanguageAndWait(
    BuildContext context,
    String code,
  ) async {
    final oldLanguage = state.languageCode;
    if (state.isLoading || code == oldLanguage) {
      return LanguageChangeResult(
        success: true,
        oldLanguage: oldLanguage,
        newLanguage: oldLanguage,
      );
    }
    emit(state.copyWith(isLoading: true));
    try {
      await _repository.changeLang(langCode: code);
      final locale = Locale(code);
      if (context.mounted) {
        await context.setLocale(locale); // rebuilds every .tr() + persists
      }
      Intl.defaultLocale = code;
      if (isClosed) {
        return LanguageChangeResult(
          success: false,
          oldLanguage: oldLanguage,
          newLanguage: code,
        );
      }
      emit(state.copyWith(locale: locale, isLoading: false));
      return LanguageChangeResult(
        success: true,
        oldLanguage: oldLanguage,
        newLanguage: code,
      );
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, error: e.toString()));
      }
      return LanguageChangeResult(
        success: false,
        oldLanguage: oldLanguage,
        newLanguage: oldLanguage,
      );
    }
  }

  /// Toggle between the two supported locales.
  Future<LanguageChangeResult> toggle(BuildContext context) =>
      changeLanguageAndWait(context, state.isArabic ? 'en' : 'ar');
}
