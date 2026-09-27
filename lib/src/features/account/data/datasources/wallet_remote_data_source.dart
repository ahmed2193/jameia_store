import '../../../../core/data/models/remote_payload.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/ledger_page_model.dart';
import '../models/ledger_results.dart';
import '../models/wallet_entry_model.dart';

/// Receives the envelope's `results` (unwrapped by `DioConsumer`); throws
/// `AppException` only. Bearer + refresh are automatic (`AuthInterceptor`).
abstract class WalletRemoteDataSource {
  /// `GET /v1/account/wallet?page&limit` (Bearer) — with the raw `results`,
  /// which the repository keeps on the device for page 1.
  Future<RemotePayload<LedgerPageModel<WalletEntryModel>>> getLedger({
    required int page,
    required int limit,
  });
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  const WalletRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  static const String pageField = 'page';
  static const String limitField = 'limit';
  static const String balanceField = LedgerResults.walletBalanceField;

  @override
  Future<RemotePayload<LedgerPageModel<WalletEntryModel>>> getLedger({
    required int page,
    required int limit,
  }) async {
    final results = ApiPayload.asMap(
      await _api.get(
        EndPoints.accountWallet,
        queryParameters: <String, dynamic>{pageField: page, limitField: limit},
      ),
      EndPoints.accountWallet,
    );
    return RemotePayload(LedgerResults.wallet(results, page: page), results);
  }
}
