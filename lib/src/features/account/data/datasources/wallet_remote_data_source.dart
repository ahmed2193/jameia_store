import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/ledger_page_model.dart';
import '../models/wallet_entry_model.dart';

/// Receives the envelope's `results` (unwrapped by `DioConsumer`); throws
/// `AppException` only. Bearer + refresh are automatic (`AuthInterceptor`).
abstract class WalletRemoteDataSource {
  /// `GET /v1/account/wallet?page&limit` (Bearer).
  Future<LedgerPageModel<WalletEntryModel>> getLedger({
    required int page,
    required int limit,
  });
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  const WalletRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  static const String pageField = 'page';
  static const String limitField = 'limit';
  static const String balanceField = 'wallet';
  static const String _logName = 'WalletRemoteDataSource';

  @override
  Future<LedgerPageModel<WalletEntryModel>> getLedger({
    required int page,
    required int limit,
  }) async {
    final results = await _api.get(
      EndPoints.accountWallet,
      queryParameters: <String, dynamic>{pageField: page, limitField: limit},
    );
    return LedgerPageModel<WalletEntryModel>.fromJson(
      ApiPayload.asMap(results, EndPoints.accountWallet),
      balanceField: balanceField,
      parseRow: WalletEntryModel.fromJson,
      requestedPage: page,
      logName: _logName,
    );
  }
}
