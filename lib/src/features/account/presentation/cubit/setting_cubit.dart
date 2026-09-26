import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/motion/haptics.dart';
import '../../../../core/navigation/app_keys.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../../core/utils/data_refresh_coordinator.dart';
import '../../../../core/utils/performance/safe_cubit_mixin.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import '../../domain/usecases/clear_app_cache_usecase.dart';
import '../../domain/usecases/get_notifications_enabled_usecase.dart';
import '../../domain/usecases/set_notifications_enabled_usecase.dart';
import 'setting_state.dart';

/// App-root Settings cubit: the user-initiated language switch (models
/// khayool's `SettingCubit.changeLanguage`), the push-notification choice and
/// the cache clean-up.
///
/// The three use cases are optional only until the app root injects them
/// (`AppGlobalCubits`); without them the choice lives in memory for the run
/// and the clean-up has nothing to empty.
class SettingCubit extends Cubit<SettingState>
    with SafeCubitMixin<SettingState> {
  SettingCubit({
    GetNotificationsEnabledUseCase? getNotificationsEnabled,
    SetNotificationsEnabledUseCase? setNotificationsEnabled,
    ClearAppCacheUseCase? clearAppCache,
  }) : _getNotificationsEnabled = getNotificationsEnabled,
       _setNotificationsEnabled = setNotificationsEnabled,
       _clearAppCache = clearAppCache,
       super(const SettingState());

  final GetNotificationsEnabledUseCase? _getNotificationsEnabled;
  final SetNotificationsEnabledUseCase? _setNotificationsEnabled;
  final ClearAppCacheUseCase? _clearAppCache;

  /// Lets the locale rebuild settle before the post-switch refresh.
  static const Duration _refreshDelay = Duration(milliseconds: 200);

  /// Bumped by every notifications write: only the latest one may roll back.
  int _notificationsWrite = 0;

  /// Reads the stored push-notification choice (a sync device read).
  void loadPreferences() {
    final read = _getNotificationsEnabled;
    if (read == null) return;
    read(const NoParams()).fold(
      (failure) => safeEmit(state.copyWith(failure: failure)),
      (enabled) => safeEmit(state.copyWith(notificationsEnabled: enabled)),
    );
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
  /// widget tree for `context.setLocale`), fires the success haptic and
  /// schedules the post-switch refresh on the global navigator context,
  /// which survives the rebuild. Completes once the new locale is applied,
  /// so a caller can hold a veil over exactly the switch.
  ///
  /// Known debt (§12): the `BuildContext` parameter, inherited from
  /// [LocalizationCubit.changeLanguageAndWait].
  Future<void> changeLanguage(BuildContext context, String languageCode) async {
    if (state.isChangingLanguage) return;

    final localizationCubit = context.read<LocalizationCubit>();
    if (localizationCubit.state.languageCode == languageCode) return;

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
        return;
      }
      Haptics.success();
      safeEmit(state.copyWith(isChangingLanguage: false));
      unawaited(_refreshAfterLanguageChange());
    } on Object catch (e) {
      safeEmit(
        state.copyWith(
          isChangingLanguage: false,
          failure: UnexpectedFailure(e.toString()),
        ),
      );
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
