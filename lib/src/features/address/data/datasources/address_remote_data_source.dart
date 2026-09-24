import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/address_model.dart';

/// The jm3eia address-book routes (customer only, Bearer attached by the
/// network layer). Receives the envelope's `results` and throws
/// `AppException` only.
///
/// Reference: https://docs.jm3eia.store/developers/account.html
abstract class AddressRemoteDataSource {
  /// `GET /v1/account/addresses` → `[Address]`.
  Future<List<AddressModel>> getAddresses();

  /// `POST /v1/account/addresses` → `{ address }`.
  Future<AddressModel> createAddress(Map<String, Object?> body);

  /// `PATCH /v1/account/addresses/:addressId` (changed fields only) →
  /// `{ address }`.
  Future<AddressModel> updateAddress(String id, Map<String, Object?> body);

  /// `DELETE /v1/account/addresses/:addressId` → `{ message }`.
  Future<void> deleteAddress(String id);
}

class AddressRemoteDataSourceImpl implements AddressRemoteDataSource {
  const AddressRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;

  /// The saved row inside a POST / PATCH reply.
  static const String addressField = 'address';

  @override
  Future<List<AddressModel>> getAddresses() async {
    final results = await _api.get(EndPoints.accountAddresses);
    if (results is! List) {
      throw ParsingException(
        '${EndPoints.accountAddresses}: unexpected payload '
        '${results.runtimeType}',
      );
    }
    return AddressModel.listFromJson(results);
  }

  @override
  Future<AddressModel> createAddress(Map<String, Object?> body) async {
    final results = await _api.post(EndPoints.accountAddresses, body: body);
    return _savedAddress(results, EndPoints.accountAddresses);
  }

  @override
  Future<AddressModel> updateAddress(
    String id,
    Map<String, Object?> body,
  ) async {
    final path = _pathOf(id);
    final results = await _api.patch(path, body: body);
    return _savedAddress(results, path);
  }

  @override
  Future<void> deleteAddress(String id) async {
    await _api.delete(_pathOf(id));
  }

  /// Only an ObjectId may become the path segment: `..` or `a/b` would send
  /// the customer's token to another route.
  static String _pathOf(String id) {
    if (!AddressModel.isObjectId(id)) {
      throw ParsingException('address: bad id $id');
    }
    return EndPoints.accountAddress(id);
  }

  static AddressModel _savedAddress(Object? results, String route) {
    final row = ApiPayload.asMap(results, route)[addressField];
    if (row is! Map) throw ParsingException('$route: address missing');
    return AddressModel.fromJson(row.cast<String, dynamic>());
  }
}
