import '../../../../core/data/hero_repository.dart';
import '../../../../core/data/models/models.dart';

/// Offline source for the account ("Mine") surfaces. The live Hero tab hits the
/// user / coupon / favourite / message-count endpoints; here everything comes
/// from the in-memory [HeroRepository]. The unread customer-service count has no
/// offline source (API `/csapi/chat/message/count`), so it is a fixed stub.
abstract class AccountLocalDataSource {
  UserProfile user();
  int couponCount();

  /// Counted off the start-up path, on the first call (BX-05).
  Future<int> favouriteCount();
  int customerServiceUnread();
}

class AccountLocalDataSourceImpl implements AccountLocalDataSource {
  AccountLocalDataSourceImpl(this.catalog);

  final HeroRepository catalog;

  @override
  UserProfile user() => catalog.user;

  @override
  int couponCount() => catalog.coupons.where((c) => !c.used).length;

  @override
  Future<int> favouriteCount() => catalog.shopCount();

  @override
  // Offline stub for `/csapi/chat/message/count` — no live message source.
  int customerServiceUnread() => 3;
}
