import '../../../../core/data/models/json_read.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/pro_program_model.dart';
import '../models/pro_subscription_model.dart';

/// Receives the envelope's `results` (unwrapped by `DioConsumer`); throws
/// `AppException` only. Bearer + refresh are automatic (`AuthInterceptor`).
abstract class ProMembershipRemoteDataSource {
  /// `GET /v1/subscription-plans` (public).
  Future<ProProgramModel> getProgram();

  /// `GET /v1/account/subscription` (Bearer) — `results` is the subscription
  /// or `null`.
  Future<ProSubscriptionModel?> getSubscription();

  /// `POST /v1/account/subscription` (Bearer) `{ planId }`.
  Future<ProSubscriptionModel> subscribe(String planId);

  /// `POST /v1/account/subscription/cancel` (Bearer).
  Future<ProSubscriptionModel> cancel();
}

class ProMembershipRemoteDataSourceImpl
    implements ProMembershipRemoteDataSource {
  const ProMembershipRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  static const String planIdField = 'planId';

  @override
  Future<ProProgramModel> getProgram() async {
    final results = await _api.get(EndPoints.subscriptionPlans);
    return ProProgramModel.fromJson(
      ApiPayload.asMap(results, EndPoints.subscriptionPlans),
    );
  }

  @override
  Future<ProSubscriptionModel?> getSubscription() async {
    final results = await _api.get(EndPoints.accountSubscription);
    final json = JsonRead.object(results);
    return json == null ? null : ProSubscriptionModel.fromJson(json);
  }

  @override
  Future<ProSubscriptionModel> subscribe(String planId) async {
    final results = await _api.post(
      EndPoints.accountSubscription,
      body: <String, dynamic>{planIdField: planId},
    );
    return ProSubscriptionModel.fromJson(
      ApiPayload.asMap(results, EndPoints.accountSubscription),
    );
  }

  @override
  Future<ProSubscriptionModel> cancel() async {
    final results = await _api.post(EndPoints.accountSubscriptionCancel);
    return ProSubscriptionModel.fromJson(
      ApiPayload.asMap(results, EndPoints.accountSubscriptionCancel),
    );
  }
}
