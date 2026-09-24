import '../../../../core/error/exceptions.dart';
import '../../../../core/storage/local_storage.dart';

/// Remembers, per marketing popup, the calendar day it was last shown — what a
/// `frequency: "day"` popup needs to stay quiet for the rest of that day.
abstract class HomeLocalDataSource {
  /// `YYYY-MM-DD` of the last showing, or `null`.
  String? popupShownDay(String popupId);

  Future<void> savePopupShownDay(String popupId, String day);
}

class HomeLocalDataSourceImpl implements HomeLocalDataSource {
  const HomeLocalDataSourceImpl(this._storage);

  final LocalStorage _storage;

  static const String _keyPrefix = 'jameia.home.popup_shown.';

  @override
  String? popupShownDay(String popupId) =>
      _storage.getString('$_keyPrefix$popupId');

  @override
  Future<void> savePopupShownDay(String popupId, String day) async {
    final saved = await _storage.setString('$_keyPrefix$popupId', day);
    if (!saved) throw const CacheException('home: popup stamp not saved');
  }
}
