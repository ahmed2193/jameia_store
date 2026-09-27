import 'dart:ui' show Locale;

import 'package:equatable/equatable.dart';

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

  const LocalizationState({
    required this.locale,
    this.isInitialized = false,
    this.isLoading = false,
  });

  String get languageCode => locale.languageCode;

  LocalizationState copyWith({
    Locale? locale,
    bool? isInitialized,
    bool? isLoading,
  }) {
    return LocalizationState(
      locale: locale ?? this.locale,
      isInitialized: isInitialized ?? this.isInitialized,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [locale, isInitialized, isLoading];
}
