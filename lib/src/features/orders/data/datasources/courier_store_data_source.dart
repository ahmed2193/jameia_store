import '../../../../core/data/models/json_read.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../models/courier_store_model.dart';

/// Where the store an order is delivered from is, and its phone line.
abstract class CourierStoreDataSource {
  /// The branch [storeId]; `null` when the branch list does not have it.
  Future<CourierStoreModel?> store(String storeId);
}

/// Reads `GET /v1/delivery/branches` once per app run (branches barely
/// change) and finds the order's branch in it; a failed read is forgotten,
/// so the next call tries again.
class CourierStoreRemoteDataSourceImpl implements CourierStoreDataSource {
  CourierStoreRemoteDataSourceImpl(this._api);

  final ApiConsumer _api;
  Future<List<CourierStoreModel>>? _branches;

  static const String dataKey = 'data';
  static const String _route = 'delivery branches';
  static const String _logName = 'CourierStore';

  @override
  Future<CourierStoreModel?> store(String storeId) async {
    if (storeId.isEmpty) return null;
    final pending = _branches ??= _load();
    final List<CourierStoreModel> branches;
    try {
      branches = await pending;
    } catch (_) {
      if (identical(_branches, pending)) _branches = null;
      rethrow;
    }
    for (final branch in branches) {
      if (branch.id == storeId) return branch;
    }
    return null;
  }

  /// `GET /v1/delivery/branches` → `{ data: [branch] }`.
  Future<List<CourierStoreModel>> _load() async {
    final results = await _api.get(EndPoints.deliveryBranches);
    return JsonRead.rows(
      ApiPayload.asMap(results, _route)[dataKey],
      CourierStoreModel.fromJson,
      logName: _logName,
    );
  }
}
