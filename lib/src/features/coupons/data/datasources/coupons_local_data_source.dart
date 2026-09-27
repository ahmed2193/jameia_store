import '../../../../core/data/hero_repository.dart';
import '../../../../core/data/models/models.dart';

/// Offline source for the user's coupons: the Hero API has no coupon wallet,
/// so the set is served from the in-memory [HeroRepository] catalogue.
abstract class CouponsLocalDataSource {
  List<Coupon> coupons();
}

class CouponsLocalDataSourceImpl implements CouponsLocalDataSource {
  const CouponsLocalDataSourceImpl(this._catalog);

  final HeroRepository _catalog;

  @override
  List<Coupon> coupons() => _catalog.coupons;
}
