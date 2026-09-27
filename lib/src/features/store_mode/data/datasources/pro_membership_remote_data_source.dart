import '../../../../core/data/models/remote_payload.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/pro_program_model.dart';
import '../models/pro_subscription_model.dart';
import '../models/pro_subscription_results.dart';

/// Receives the envelope's `results` (unwrapped by `DioConsumer`); throws
/// `AppException` only. Bearer + refresh are automatic (`AuthInterceptor`).
/// Every reply carries its raw `results` for the device copy.
abstract class ProMembershipRemoteDataSource {
  /// `GET /v1/subscription-plans` (public).
  Future<RemotePayload<ProProgramModel>> getProgram();

  /// `GET /v1/account/subscription` (Bearer) — `results` is the subscription
  /// or `null` (see [ProSubscriptionResults]).
  Future<RemotePayload<ProSubscriptionModel?>> getSubscription();

  /// `POST /v1/account/subscription` (Bearer) `{ planId }` — the new
  /// subscription, what the subscription read answers from now on.
  Future<RemotePayload<ProSubscriptionModel>> subscribe(String planId);

  /// `POST /v1/account/subscription/cancel` (Bearer) — the subscription as
  /// it now is.
  Future<RemotePayload<ProSubscriptionModel>> cancel();
}

class ProMembershipRemoteDataSourceImpl
    implements ProMembershipRemoteDataSource {
  const ProMembershipRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  static const String planIdField = 'planId';

  @override
  Future<RemotePayload<ProProgramModel>> getProgram() async {
    final results = await _api.get(EndPoints.subscriptionPlans);
    final json = ApiPayload.asMap(results, EndPoints.subscriptionPlans);
    return RemotePayload(ProProgramModel.fromJson(json), json);
  }

  @override
  Future<RemotePayload<ProSubscriptionModel?>> getSubscription() async {
    final results = await _api.get(EndPoints.accountSubscription);
    return RemotePayload(
      ProSubscriptionResults.parse(results),
      ProSubscriptionResults.keep(results),
    );
  }

  @override
  Future<RemotePayload<ProSubscriptionModel>> subscribe(String planId) async {
    final results = await _api.post(
      EndPoints.accountSubscription,
      body: <String, dynamic>{planIdField: planId},
    );
    final json = ApiPayload.asMap(results, EndPoints.accountSubscription);
    return RemotePayload(ProSubscriptionModel.fromJson(json), json);
  }

  @override
  Future<RemotePayload<ProSubscriptionModel>> cancel() async {
    final results = await _api.post(EndPoints.accountSubscriptionCancel);
    final json = ApiPayload.asMap(results, EndPoints.accountSubscriptionCancel);
    return RemotePayload(ProSubscriptionModel.fromJson(json), json);
  }
}
