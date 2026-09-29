import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/local_storage.dart';

/// The Settings screen's device state: the push-notification and vibration
/// choices in [LocalStorage] and the image cache on disk.
abstract class SettingsLocalDataSource {
  /// The stored choice, `null` when never set.
  bool? notificationsEnabled();

  /// Throws [CacheException] when the choice could not be written.
  Future<void> setNotificationsEnabled({required bool enabled});

  /// The stored vibration (haptics) choice, `null` when never set.
  bool? hapticsEnabled();

  /// Throws [CacheException] when the choice could not be written.
  Future<void> setHapticsEnabled({required bool enabled});

  /// Empties the on-disk image cache.
  Future<void> clearCache();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  /// [clearImageCache] empties the shared image cache (the DI passes
  /// `HeroImageCacheManager.clearCache`).
  const SettingsLocalDataSourceImpl(
    this._storage, {
    required this._clearImageCache,
  });

  final LocalStorage _storage;
  final Future<void> Function() _clearImageCache;

  static const String notificationsKey = 'settings.notifications.v1';
  static const String hapticsKey = 'settings.haptics.v1';

  @override
  bool? notificationsEnabled() => _storage.getBool(notificationsKey);

  @override
  Future<void> setNotificationsEnabled({required bool enabled}) async {
    final written = await _storage.setBool(notificationsKey, value: enabled);
    if (!written) {
      throw const CacheException('Could not store the notifications choice');
    }
  }

  @override
  bool? hapticsEnabled() => _storage.getBool(hapticsKey);

  @override
  Future<void> setHapticsEnabled({required bool enabled}) async {
    final written = await _storage.setBool(hapticsKey, value: enabled);
    if (!written) {
      throw const CacheException('Could not store the vibration choice');
    }
  }

  @override
  Future<void> clearCache() => _clearImageCache();
}
