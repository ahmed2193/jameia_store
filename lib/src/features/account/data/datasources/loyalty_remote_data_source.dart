import '../../../../core/data/models/loyalty_program_model.dart';
import '../../../../core/data/models/remote_payload.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/ledger_page_model.dart';
import '../models/ledger_results.dart';
import '../models/loyalty_entry_model.dart';

/// Receives the envelope's `results` (unwrapped by `DioConsumer`); throws
/// `AppException` only. Bearer + refresh are automatic (`AuthInterceptor`).
abstract class LoyaltyRemoteDataSource {
  /// `GET /v1/account/loyalty?page&limit` (Bearer) — with the raw
  /// `results`, which the repository keeps on the device for page 1.
  Future<RemotePayload<LedgerPageModel<LoyaltyEntryModel>>> getLedger({
    required int page,
    required int limit,
  });

  /// `GET /v1/init` (public) → `store.loyalty`. Store configuration, the
  /// same for every customer and language, so the first answer is kept for
  /// the rest of the run; concurrent callers share one request and a failed
  /// one is asked again next time.
  Future<LoyaltyProgramModel> getProgram();
}

class LoyaltyRemoteDataSourceImpl implements LoyaltyRemoteDataSource {
  LoyaltyRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  static const String pageField = 'page';
  static const String limitField = 'limit';
  static const String balanceField = LedgerResults.loyaltyBalanceField;

  Future<LoyaltyProgramModel>? _program;

  @override
  Future<RemotePayload<LedgerPageModel<LoyaltyEntryModel>>> getLedger({
    required int page,
    required int limit,
  }) async {
    final results = ApiPayload.asMap(
      await _api.get(
        EndPoints.accountLoyalty,
        queryParameters: <String, dynamic>{pageField: page, limitField: limit},
      ),
      EndPoints.accountLoyalty,
    );
    return RemotePayload(LedgerResults.loyalty(results, page: page), results);
  }

  @override
  Future<LoyaltyProgramModel> getProgram() {
    final known = _program;
    if (known != null) return known;
    final request = _fetchProgram();
    _program = request;
    // A failure is not kept: forget it so the next caller asks again.
    request.then<void>(
      (_) {},
      onError: (Object _) {
        if (identical(_program, request)) _program = null;
      },
    );
    return request;
  }

  Future<LoyaltyProgramModel> _fetchProgram() async {
    final results = await _api.get(EndPoints.init);
    return LoyaltyProgramModel.fromInitJson(
      ApiPayload.asMap(results, EndPoints.init),
    );
  }
}
