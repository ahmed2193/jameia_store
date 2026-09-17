import 'package:shared_preferences/shared_preferences.dart';

/// Single mediated entry point to on-device key/value storage. Feature code
/// reads/writes through THIS (resolved from `sl`), never touching
/// `SharedPreferences` directly — mirrors the reference's "single Hive box via
/// HiveController" rule, so swapping the backend later is a one-file change.
abstract class LocalStorage {
  Future<bool> setString(String key, String value);
  String? getString(String key);
  Future<bool> setBool(String key, {required bool value});
  bool? getBool(String key);
  Future<bool> remove(String key);
}

class LocalStorageImpl implements LocalStorage {
  final SharedPreferences _prefs;

  LocalStorageImpl(this._prefs);

  @override
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  String? getString(String key) => _prefs.getString(key);

  @override
  Future<bool> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  @override
  bool? getBool(String key) => _prefs.getBool(key);

  @override
  Future<bool> remove(String key) => _prefs.remove(key);
}
