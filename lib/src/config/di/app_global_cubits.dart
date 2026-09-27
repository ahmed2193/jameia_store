import '../../features/account/presentation/cubit/setting_cubit.dart';
import '../../features/address/presentation/cubit/address_book_cubit.dart';
import '../../features/assistant/presentation/cubit/assistant_availability_cubit.dart';
import '../../features/auth/presentation/cubit/auth_session_cubit.dart';
import '../../features/cart/presentation/cubit/cart_cubit.dart';
import '../../features/connectivity/presentation/cubit/connectivity_cubit.dart';
import '../../features/language/presentation/cubit/localization_cubit.dart';
import '../../features/notifications/presentation/cubit/unread_notifications_cubit.dart';
import '../../features/store_mode/presentation/cubit/pro_status_cubit.dart';
import 'service_locator.dart';

/// Factories for the app-global cubits the root `HeroApp` (`src/app.dart`)
/// provides above `MaterialApp.router`. Kept in the DI layer so `sl` is read
/// only in `config/di` / injection containers; each call resolves a fresh
/// instance from its `registerFactory`.
abstract final class AppGlobalCubits {
  /// Subscribes to the cart mirror and paints the device copy; the app root
  /// binds it to the session (onSignedIn / onGuestSession / onSignedOut).
  static CartCubit cart() => sl<CartCubit>()..start();

  static LocalizationCubit localization() => sl<LocalizationCubit>();

  /// The Settings screen's language switch, notifications choice and cache
  /// clean-up (the Settings page loads the stored choice).
  static SettingCubit setting() => sl<SettingCubit>();

  /// Follows the backend's reachability (the banner, reconnect refreshes).
  static ConnectivityCubit connectivity() => sl<ConnectivityCubit>()..start();

  /// Restores a stored session on creation (validated against the backend).
  static AuthSessionCubit authSession() => sl<AuthSessionCubit>()..restore();

  /// Saved-address book; idle until the app root calls `start()` on sign-in.
  static AddressBookCubit addressBook() => sl<AddressBookCubit>();

  /// Unread badge; idle until the app root calls `start()` on sign-in.
  static UnreadNotificationsCubit unreadNotifications() =>
      sl<UnreadNotificationsCubit>();

  /// Whether the store runs the assistant: read from `/v1/init` when the
  /// first entry point builds (the provider is lazy), never at app start.
  static AssistantAvailabilityCubit assistantAvailability() =>
      sl<AssistantAvailabilityCubit>()..ensureLoaded();

  /// Where the customer stands with Hero Pro; unsettled until the app
  /// root calls `start()` (signed in) or `stop()` (a guest).
  static ProStatusCubit proStatus() => sl<ProStatusCubit>();
}
