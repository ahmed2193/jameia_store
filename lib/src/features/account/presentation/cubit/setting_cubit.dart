import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/navigation/app_keys.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/data_refresh_coordinator.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../domain/usecases/clear_app_cache_usecase.dart';
import '../../domain/usecases/get_haptics_enabled_usecase.dart';
import '../../domain/usecases/get_notifications_enabled_usecase.dart';
import '../../domain/usecases/set_haptics_enabled_usecase.dart';
import '../../domain/usecases/set_notifications_enabled_usecase.dart';
import 'setting_state.dart';

/// App-root Settings cubit: the user-initiated language switch (models
/// khayool's `SettingCubit.changeLanguage`), the push-notification and
/// vibration choices and the cache clean-up.
///
/// The app root injects the use cases (`AppGlobalCubits.setting`), reads the
/// stored choices at launch and applies [SettingState.hapticsEnabled] to the
/// haptics mute; a test may leave the use cases out, and then the choices
/// live in memory for the run and the clean-up has nothing to empty.
class SettingCubit extends Cubit<SettingState>
    with SafeCubitMixin<SettingState> {
  SettingCubit({
    this._getNotificationsEnabled,
    this._setNotificationsEnabled,
    this._clearAppCache,
    this._getHapticsEnabled,
    this._setHapticsEnabled,
  }) : super(const SettingState());

  final GetNotificationsEnabledUseCase? _getNotificationsEnabled;
  final SetNotificationsEnabledUseCase? _setNotificationsEnabled;
  final ClearAppCacheUseCase? _clearAppCache;
  final GetHapticsEnabledUseCase? _getHapticsEnabled;
  final SetHapticsEnabledUseCase? _setHapticsEnabled;

  /// Lets the locale rebuild settle before the post-switch refresh.
  static const Duration _refreshDelay = Duration(milliseconds: 200);

  /// Bumped by every notifications write: only the latest one may roll back.
  int _notificationsWrite = 0;

  /// Bumped by every vibration write: only the latest one may roll back.
  int _hapticsWrite = 0;

  /// Reads the stored push-notification and vibration choices (sync device
  /// reads).
  void loadPreferences() {
    final notifications = _getNotificationsEnabled;
    if (notifications != null) {
      notifications(const NoParams()).fold(
        (failure) => safeEmit(state.copyWith(failure: failure)),
        (enabled) => safeEmit(state.copyWith(notificationsEnabled: enabled)),
      );
    }
    final haptics = _getHapticsEnabled;
    if (haptics != null) {
      haptics(const NoParams()).fold(
        (failure) => safeEmit(state.copyWith(failure: failure)),
        (enabled) => safeEmit(state.copyWith(hapticsEnabled: enabled)),
      );
    }
  }

  /// Flips the switch at once, then stores the choice; a failed write puts
  /// the switch back and reports the failure.
  Future<void> setNotificationsEnabled(bool enabled) async {
    final previous = state.notificationsEnabled;
    if (enabled == previous) return;
    final write = ++_notificationsWrite;
    safeEmit(state.copyWith(notificationsEnabled: enabled));
    final store = _setNotificationsEnabled;
    if (store == null) return;
    final result = await store(SetNotificationsEnabledParams(enabled: enabled));
    if (write != _notificationsWrite) return; // a newer tap owns the switch
    result.fold(
      (failure) => safeEmit(
        state.copyWith(notificationsEnabled: previous, failure: failure),
      ),
      (_) {},
    );
  }

  /// Flips the vibration switch at once, then stores the choice; a failed
  /// write puts the switch back and reports the failure.
  Future<void> setHapticsEnabled(bool enabled) async {
    final previous = state.hapticsEnabled;
    if (enabled == previous) return;
    final write = ++_hapticsWrite;
    safeEmit(state.copyWith(hapticsEnabled: enabled));
    final store = _setHapticsEnabled;
    if (store == null) return;
    final result = await store(SetHapticsEnabledParams(enabled: enabled));
    if (write != _hapticsWrite) return; // a newer tap owns the switch
    result.fold(
      (failure) =>
          safeEmit(state.copyWith(hapticsEnabled: previous, failure: failure)),
      (_) {},
    );
  }

  /// Empties the image cache. [SettingState.isClearingCache] is on while it
  /// runs; a second tap meanwhile is ignored.
  Future<void> clearCache() async {
    if (state.isClearingCache) return;
    safeEmit(state.copyWith(isClearingCache: true));
    final clear = _clearAppCache;
    if (clear == null) {
      safeEmit(state.copyWith(isClearingCache: false));
      return;
    }
    final result = await clear(const NoParams());
    result.fold(
      (failure) =>
          safeEmit(state.copyWith(isClearingCache: false, failure: failure)),
      (_) => safeEmit(state.copyWith(isClearingCache: false)),
    );
  }

  /// Switches the app language through [LocalizationCubit] (which needs the
  /// widget tree for `context.setLocale`) and schedules the post-switch
  /// refresh on the global navigator context, which survives the rebuild.
  /// Completes once the new locale is applied, so a caller can hold a veil
  /// over exactly the switch — with `true` when the language did switch (the
  /// widget that owns the gesture fires the success haptic, never this cubit).
  ///
  /// [context] must outlive the switch (the caller passes the app's, not a
  /// page's); it is read before the first await only. One already gone
  /// switches nothing.
  ///
  /// Known debt (§12): the `BuildContext` parameter, inherited from
  /// [LocalizationCubit.changeLanguageAndWait].
  Future<bool> changeLanguage(BuildContext context, String languageCode) async {
    if (state.isChangingLanguage || !context.mounted) return false;

    final localizationCubit = context.read<LocalizationCubit>();
    if (localizationCubit.state.languageCode == languageCode) return false;

    safeEmit(state.copyWith(isChangingLanguage: true));
    try {
      final result = await localizationCubit.changeLanguageAndWait(
        context,
        languageCode,
      );
      if (!result.success) {
        safeEmit(
          state.copyWith(
            isChangingLanguage: false,
            failure: const UnexpectedFailure('Language change failed'),
          ),
        );
        return false;
      }
      safeEmit(state.copyWith(isChangingLanguage: false));
      unawaited(_refreshAfterLanguageChange());
      return true;
    } on Object catch (e) {
      safeEmit(
        state.copyWith(
          isChangingLanguage: false,
          failure: UnexpectedFailure(e.toString()),
        ),
      );
      return false;
    }
  }

  Future<void> _refreshAfterLanguageChange() async {
    await Future<void>.delayed(_refreshDelay);
    final refreshContext = navigatorKey.currentContext;
    if (refreshContext != null && refreshContext.mounted) {
      DataRefreshCoordinator.instance.refreshForLanguageChange(refreshContext);
    }
  }
}
