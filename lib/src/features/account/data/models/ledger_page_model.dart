import '../../../../core/data/models/json_read.dart';

/// `results` of an account ledger route — `GET /v1/account/wallet` and
/// `GET /v1/account/loyalty` share the shape:
/// `{ balance: { wallet | loyaltyPoints: int }, data: [row], pagination:
/// { total, page, limit, hasMore } }`. A malformed row is skipped, never the
/// page.
class LedgerPageModel<M> {
  const LedgerPageModel({
    required this.balance,
    required this.items,
    required this.page,
    this.hasMore = false,
    this.total = 0,
  });

  static const String balanceKey = 'balance';
  static const String dataKey = 'data';
  static const String paginationKey = 'pagination';
  static const String totalKey = 'total';
  static const String pageKey = 'page';
  static const String hasMoreKey = 'hasMore';

  /// [balanceField] names the balance inside `balance` (`wallet` /
  /// `loyaltyPoints`); [parseRow] throws `AppException` on a broken row.
  factory LedgerPageModel.fromJson(
    Map<String, dynamic> json, {
    required String balanceField,
    required M Function(Map<String, dynamic> json) parseRow,
    required int requestedPage,
    required String logName,
  }) {
    final balance = JsonRead.object(json[balanceKey]);
    final pagination = JsonRead.object(json[paginationKey]);
    return LedgerPageModel<M>(
      balance: JsonRead.integer(balance?[balanceField]) ?? 0,
      items: JsonRead.rows(json[dataKey], parseRow, logName: logName),
      page: JsonRead.integer(pagination?[pageKey]) ?? requestedPage,
      hasMore: pagination != null && JsonRead.flag(pagination[hasMoreKey]),
      total: JsonRead.integer(pagination?[totalKey]) ?? 0,
    );
  }

  /// Fils (wallet) or points (loyalty).
  final int balance;
  final List<M> items;
  final int page;
  final bool hasMore;
  final int total;
}
