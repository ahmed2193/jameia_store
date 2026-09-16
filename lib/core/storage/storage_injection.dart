import 'package:shared_preferences/shared_preferences.dart';

import '../config/service_locator.dart';
import 'local_storage.dart';

/// Core storage DI — registers the shared [LocalStorage] (and its backing
/// [SharedPreferences]) exactly once, from the core bootstrap in `main.dart`,
/// BEFORE any feature init. Features only ever *resolve* `sl<LocalStorage>()`,
/// so they no longer depend on each other's registration order (previously the
/// cart/language ICs each registered it defensively and `search` silently relied
/// on one of them having run first).
Future<void> initCoreStorage() async {
  if (sl.isRegistered<LocalStorage>()) return; // idempotent
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerSingleton<LocalStorage>(LocalStorageImpl(prefs));
}
