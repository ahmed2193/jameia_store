import '../../../../core/data/datasources/cache_slots.dart';
import '../../../../core/storage/cache_namespace.dart';
import '../models/ledger_page_model.dart';
import '../models/ledger_results.dart';
import '../models/loyalty_entry_model.dart';
import '../models/wallet_entry_model.dart';

/// The wallet and points histories as last shown: the first page of each
/// (the balance with it), per language. Customer-only — nothing is kept for
/// a guest — and wiped on sign-out. Parsed back with the reply's own parser
/// ([LedgerResults]).
abstract class LedgerCacheDataSource {
  /// `GET /v1/account/wallet` — the first page of [limit].
  CacheSlot<LedgerPageModel<WalletEntryModel>>? wallet({required int limit});

  /// `GET /v1/account/loyalty` — the first page of [limit].
  CacheSlot<LedgerPageModel<LoyaltyEntryModel>>? loyalty({required int limit});
}

class LedgerCacheDataSourceImpl implements LedgerCacheDataSource {
  const LedgerCacheDataSourceImpl(this._slots);

  final CacheSlots _slots;

  static const int _firstPage = 1;

  static const CacheNamespace walletNamespace = CacheNamespace(
    'account.wallet',
    scope: CacheScope.customer,
    freshFor: Duration(seconds: 60),
    maxAge: Duration(days: 14),
  );

  static const CacheNamespace loyaltyNamespace = CacheNamespace(
    'account.loyalty',
    scope: CacheScope.customer,
    freshFor: Duration(seconds: 60),
    maxAge: Duration(days: 14),
  );

  @override
  CacheSlot<LedgerPageModel<WalletEntryModel>>? wallet({required int limit}) =>
      _slots.of(
        walletNamespace,
        id: '$limit',
        parse: (raw) => LedgerResults.wallet(raw, page: _firstPage),
      );

  @override
  CacheSlot<LedgerPageModel<LoyaltyEntryModel>>? loyalty({
    required int limit,
  }) => _slots.of(
    loyaltyNamespace,
    id: '$limit',
    parse: (raw) => LedgerResults.loyalty(raw, page: _firstPage),
  );
}
