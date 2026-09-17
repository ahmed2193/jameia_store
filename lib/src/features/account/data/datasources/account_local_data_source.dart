import '../../../../core/data/jameia_repository.dart';
import '../../../../core/data/models/models.dart';

/// Offline source for the account ("Mine") surfaces. The live Jameia tab hits the
/// user / coupon / favourite / message-count endpoints; here everything comes
/// from the in-memory [JameiaRepository]. The unread customer-service count has no
/// offline source (API `/csapi/chat/message/count`), so it is a fixed stub.
abstract class AccountLocalDataSource {
  UserProfile user();
  int couponCount();
  int favouriteCount();
  int customerServiceUnread();
}

class AccountLocalDataSourceImpl implements AccountLocalDataSource {
  AccountLocalDataSourceImpl(this.catalog);

  final JameiaRepository catalog;

  @override
  UserProfile user() => catalog.user;

  @override
  int couponCount() => catalog.coupons.where((c) => !c.used).length;

  @override
  int favouriteCount() => catalog.shops.length;

  @override
  // Offline stub for `/csapi/chat/message/count` — no live message source.
  int customerServiceUnread() => 3;
}
