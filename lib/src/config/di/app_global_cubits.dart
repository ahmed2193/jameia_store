import '../../features/auth/presentation/cubit/auth_session_cubit.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/language/presentation/cubit/localization_cubit.dart';
import '../../features/notifications/presentation/cubit/unread_notifications_cubit.dart';
import '../../features/store_mode/presentation/cubit/store_mode_cubit.dart';
import 'service_locator.dart';

/// Factories for the app-global cubits the root `JameiaApp` (`src/app.dart`)
/// provides above `MaterialApp.router`. Kept in the DI layer so `sl` is read
/// only in `config/di` / injection containers; each call resolves a fresh
/// instance from its `registerFactory`.
abstract final class AppGlobalCubits {
  static CartCubit cart() => sl<CartCubit>();

  static StoreModeCubit storeMode() => sl<StoreModeCubit>();

  static LocalizationCubit localization() => sl<LocalizationCubit>();

  /// Restores a stored session on creation (validated against the backend).
  static AuthSessionCubit authSession() => sl<AuthSessionCubit>()..restore();

  /// Unread badge; idle until the app root calls `start()` on sign-in.
  static UnreadNotificationsCubit unreadNotifications() =>
      sl<UnreadNotificationsCubit>();
}
