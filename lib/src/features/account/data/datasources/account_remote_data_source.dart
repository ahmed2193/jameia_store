import '../../../../core/data/models/customer_model.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';

/// The jm3eia account endpoints a signed-in customer owns. Receives the
/// envelope's `results` (unwrapped by `DioConsumer`) and throws `AppException`
/// only.
///
/// Reference: https://docs.jm3eia.store/developers/account.html
abstract class AccountRemoteDataSource {
  /// `GET /v1/account/me` (Bearer).
  Future<CustomerModel> me();

  /// `PATCH /v1/account/profile` (Bearer) with the changed fields only —
  /// `name`, `email` (null clears), `language`, `dateOfBirth`, `gender`,
  /// `householdSize`. Returns the updated customer.
  Future<CustomerModel> updateProfile(Map<String, Object?> body);
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  const AccountRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  @override
  Future<CustomerModel> me() async {
    final results = await _api.get(EndPoints.accountMe);
    return CustomerModel.fromJson(
      ApiPayload.asMap(results, EndPoints.accountMe),
    );
  }

  @override
  Future<CustomerModel> updateProfile(Map<String, Object?> body) async {
    final results = await _api.patch(EndPoints.accountProfile, body: body);
    return CustomerModel.fromJson(
      ApiPayload.asMap(results, EndPoints.accountProfile),
    );
  }
}
