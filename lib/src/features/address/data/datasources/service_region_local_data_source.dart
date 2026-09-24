import '../../../../core/data/jameia_repository.dart';
import '../../../../core/utils/jameia_geocode.dart';

/// Offline source for the serviceable-region picker: the hard-coded region
/// anchors (`JameiaGeocode`) and the active region the catalogue keeps (its
/// notifier broadcasts a switch).
abstract class ServiceRegionLocalDataSource {
  /// Serviceable-region anchors (`JameiaGeocode.openServiceRegions`).
  List<ServiceRegionItem> serviceRegions();

  /// The active two-letter region code.
  String activeRegion();

  /// Commit a region switch.
  void switchRegion(String region);
}

class ServiceRegionLocalDataSourceImpl implements ServiceRegionLocalDataSource {
  const ServiceRegionLocalDataSourceImpl(this._catalog);

  final JameiaRepository _catalog;

  @override
  List<ServiceRegionItem> serviceRegions() =>
      JameiaGeocode.openServiceRegions();

  @override
  String activeRegion() => _catalog.activeRegion;

  @override
  void switchRegion(String region) => _catalog.switchRegion(region);
}
