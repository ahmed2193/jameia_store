import 'package:equatable/equatable.dart';

/// UI orchestration state for language switching — models the relevant slice of
/// khayool's `SettingState`. `isChangingLanguage` drives the [LanguageIconButton]
/// spinner and disables re-tap while a switch is in flight.
class SettingState extends Equatable {
  final bool isChangingLanguage;

  /// Transient error from the last operation — reset on each [copyWith].
  final String? error;

  const SettingState({this.isChangingLanguage = false, this.error});

  SettingState copyWith({bool? isChangingLanguage, String? error}) {
    return SettingState(
      isChangingLanguage: isChangingLanguage ?? this.isChangingLanguage,
      error: error,
    );
  }

  @override
  List<Object?> get props => [isChangingLanguage, error];
}
