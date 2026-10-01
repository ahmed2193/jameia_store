import '../../../../core/data/hero_repository.dart';
import '../../../../core/data/models/models.dart';

/// Offline source for the account ("Mine") surfaces: the seeded profile and
/// the coupon wallet's count, from the in-memory [HeroRepository]. (No
/// favourites or customer-service unread count: neither has a source yet,
/// so Mine shows neither.)
abstract class AccountLocalDataSource {
  UserProfile user();
  int couponCount();
}

class AccountLocalDataSourceImpl implements AccountLocalDataSource {
  AccountLocalDataSourceImpl(this.catalog);

  final HeroRepository catalog;

  @override
  UserProfile user() => catalog.user;

  @override
  int couponCount() => catalog.coupons.where((c) => !c.used).length;
}
