import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';

/// Offline source for the user's coupons. The live KeeTa pages hit the coupon
/// list endpoints; here the coupon set is served straight from the in-memory
/// [KeetaRepository] (the same dummy data the screens read inline before the
/// clean-arch conversion).
abstract class CouponsLocalDataSource {
  List<Coupon> coupons();
}

class CouponsLocalDataSourceImpl implements CouponsLocalDataSource {
  CouponsLocalDataSourceImpl(this.catalog);

  final KeetaRepository catalog;

  @override
  List<Coupon> coupons() => catalog.coupons;
}
