import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// Immutable locale state — models khayool's `LocalizationState`, minus the
/// `rebuildKey` counter (deleted: it had no consumer; widgets that need the
/// current language read [locale] here or `context.locale`).
class LocalizationState extends Equatable {
  final Locale locale;

  /// Set once launch-time restore has applied the saved locale (guards double
  /// init and the one-shot post-frame `initializeLocale` call).
  final bool isInitialized;

  /// True while a switch is applying (re-entrancy guard in the cubit).
  final bool isLoading;

  /// Transient error from the last operation — reset on each [copyWith].
  final String? error;

  const LocalizationState({
    required this.locale,
    this.isInitialized = false,
    this.isLoading = false,
    this.error,
  });

  bool get isArabic => locale.languageCode == 'ar';
  bool get isEnglish => locale.languageCode == 'en';
  String get languageCode => locale.languageCode;
  bool get hasError => error != null;

  LocalizationState copyWith({
    Locale? locale,
    bool? isInitialized,
    bool? isLoading,
    String? error, // NOT `?? this.error` — transient, cleared each copyWith
  }) {
    return LocalizationState(
      locale: locale ?? this.locale,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  List<Object?> get props => [locale, isInitialized, isLoading, error];
}
