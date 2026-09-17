import '../../../../core/data/jameia_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/utils/jameia_geocode.dart';

/// Offline source for the saved-address book + serviceable-region picker.
///
/// The live Jameia flows hit `saveOrUpdateV2` / `DELUSERADDRESS` / `switchRegion`;
/// here every persisted read/write delegates to the in-memory
/// [JameiaRepository], which owns the `shared_preferences`-backed address book and
/// the active-address / active-region [ValueNotifier]s. The region ANCHORS are a
/// pure `JameiaGeocode` derivation (hard-coded serviceable regions), so they are
/// resolved from the util at call time.
///
/// Delegating to the EXACT [JameiaRepository] operations is what keeps add / edit
/// / delete / set-primary persisting across app restarts and keeps the
/// active-address notifier updating.
abstract class AddressLocalDataSource {
  /// Raw saved-address book (unsorted — the use case hoists the default).
  List<JameiaAddress> addresses();

  /// Insert or update a saved address (`upsertAddress`) — persists + records its
  /// coordinate. Returns the saved row.
  JameiaAddress upsertAddress(JameiaAddress address);

  /// Delete a saved address by id (`deleteAddress`) — persists + clears the
  /// active selection when it pointed at the deleted row.
  void deleteAddress(String id);

  /// Select the active delivery address (`selectActiveAddress`) — updates the
  /// active-address notifier + records its coordinate.
  void selectActiveAddress(String id);

  /// Serviceable-region anchors (`JameiaGeocode.openServiceRegions`).
  List<ServiceRegionItem> serviceRegions();

  /// The active two-letter region code (`activeRegion`).
  String activeRegion();

  /// Commit a region switch (`switchRegion`).
  void switchRegion(String region);
}

class AddressLocalDataSourceImpl implements AddressLocalDataSource {
  AddressLocalDataSourceImpl(this.catalog);

  final JameiaRepository catalog;

  @override
  List<JameiaAddress> addresses() => catalog.addresses;

  @override
  JameiaAddress upsertAddress(JameiaAddress address) =>
      catalog.upsertAddress(address);

  @override
  void deleteAddress(String id) => catalog.deleteAddress(id);

  @override
  void selectActiveAddress(String id) => catalog.selectActiveAddress(id);

  @override
  List<ServiceRegionItem> serviceRegions() =>
      JameiaGeocode.openServiceRegions();

  @override
  String activeRegion() => catalog.activeRegion;

  @override
  void switchRegion(String region) => catalog.switchRegion(region);
}
