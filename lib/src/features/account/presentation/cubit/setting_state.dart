import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';

/// App-wide Settings state: the language switch in flight (it disables the
/// language controls), the push-notification choice and the cache clean-up
/// in flight.
class SettingState extends Equatable {
  const SettingState({
    this.isChangingLanguage = false,
    this.notificationsEnabled = true,
    this.isClearingCache = false,
    this.failure,
  });

  final bool isChangingLanguage;
  final bool notificationsEnabled;
  final bool isClearingCache;

  /// What the last operation failed with. Transient: every [copyWith] clears
  /// it, so the page reacts to it once.
  final Failure? failure;

  SettingState copyWith({
    bool? isChangingLanguage,
    bool? notificationsEnabled,
    bool? isClearingCache,
    Failure? failure,
  }) {
    return SettingState(
      isChangingLanguage: isChangingLanguage ?? this.isChangingLanguage,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      isClearingCache: isClearingCache ?? this.isClearingCache,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [
    isChangingLanguage,
    notificationsEnabled,
    isClearingCache,
    failure,
  ];
}
