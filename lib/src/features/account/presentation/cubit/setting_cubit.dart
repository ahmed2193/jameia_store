import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/navigation/app_keys.dart';
import '../../../../core/utils/data_refresh_coordinator.dart';
import '../../../language/presentation/cubit/localization_cubit.dart';
import 'setting_state.dart';

/// Orchestrates a user-initiated language change — models khayool's
/// `SettingCubit.changeLanguage`.
///
/// Owns the `isChangingLanguage` flag that drives the [LanguageIconButton]
/// spinner, guards against re-entrant taps, fires the success haptic, then —
/// after letting the locale rebuild settle — runs the post-switch data refresh
/// via the GLOBAL navigator context (which survives the rebuild, unlike a screen
/// context that can unmount mid-refresh).
class SettingCubit extends Cubit<SettingState> {
  SettingCubit() : super(const SettingState());

  bool _isDisposed = false;

  void _safeEmit(SettingState next) {
    if (!_isDisposed && !isClosed) emit(next);
  }

  Future<void> changeLanguage(BuildContext context, String languageCode) async {
    if (state.isChangingLanguage) return;

    final localizationCubit = context.read<LocalizationCubit>();
    if (localizationCubit.state.languageCode == languageCode) return;

    _safeEmit(state.copyWith(isChangingLanguage: true));
    try {
      final result = await localizationCubit.changeLanguageAndWait(
        context,
        languageCode,
      );

      if (!result.success) {
        _safeEmit(
          state.copyWith(
            isChangingLanguage: false,
            error: 'language_change_failed',
          ),
        );
        return;
      }

      HapticFeedback.mediumImpact();
      _safeEmit(state.copyWith(isChangingLanguage: false));

      // Let the locale rebuild fully propagate before the data refresh.
      await Future.delayed(const Duration(milliseconds: 200));
      final refreshContext = navigatorKey.currentContext;
      if (refreshContext != null && refreshContext.mounted) {
        DataRefreshCoordinator.instance.refreshForLanguageChange(
          refreshContext,
        );
      }
    } catch (e) {
      _safeEmit(state.copyWith(isChangingLanguage: false, error: e.toString()));
    }
  }

  @override
  Future<void> close() {
    _isDisposed = true;
    return super.close();
  }
}
