import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import 'ledger_page_model.dart';
import 'loyalty_entry_model.dart';
import 'wallet_entry_model.dart';

/// Parses the `results` of the two account ledger routes — the server's
/// reply and its device copy alike.
abstract final class LedgerResults {
  /// Where each route puts its balance inside `balance`.
  static const String walletBalanceField = 'wallet';
  static const String loyaltyBalanceField = 'loyaltyPoints';

  static const String _walletLog = 'WalletRemoteDataSource';
  static const String _loyaltyLog = 'LoyaltyRemoteDataSource';

  /// `GET /v1/account/wallet` — the balance in fils plus one page.
  static LedgerPageModel<WalletEntryModel> wallet(
    Object? results, {
    required int page,
  }) => LedgerPageModel<WalletEntryModel>.fromJson(
    ApiPayload.asMap(results, EndPoints.accountWallet),
    balanceField: walletBalanceField,
    parseRow: WalletEntryModel.fromJson,
    requestedPage: page,
    logName: _walletLog,
  );

  /// `GET /v1/account/loyalty` — the points balance plus one page.
  static LedgerPageModel<LoyaltyEntryModel> loyalty(
    Object? results, {
    required int page,
  }) => LedgerPageModel<LoyaltyEntryModel>.fromJson(
    ApiPayload.asMap(results, EndPoints.accountLoyalty),
    balanceField: loyaltyBalanceField,
    parseRow: LoyaltyEntryModel.fromJson,
    requestedPage: page,
    logName: _loyaltyLog,
  );
}
