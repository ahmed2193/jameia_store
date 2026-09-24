import '../../../../core/data/models/json_read.dart';
import '../../../../core/network/api_consumer.dart';
import '../../../../core/network/api_payload.dart';
import '../../../../core/network/end_points.dart';
import '../../../../core/network/locale_provider.dart';
import '../models/branch_model.dart';
import '../models/delivery_selection_model.dart';
import '../models/delivery_slot_model.dart';

/// The jm3eia delivery routes checkout needs. `results` only (the envelope
/// is unwrapped by `DioConsumer`); throws `AppException`.
///
/// Reference: https://docs.jm3eia.store/developers/ (Delivery).
abstract class DeliveryRemoteDataSource {
  /// `GET /v1/delivery/branches` → `{ data: [Branch] }`. Branch names arrive
  /// resolved for `Accept-Language`, so the answer is kept per language and
  /// only for [DeliveryRemoteDataSourceImpl.branchesTtl].
  Future<List<BranchModel>> getBranches();

  /// `GET /v1/delivery/slots` → `{ data: [{ date, label, slots }] }`.
  Future<List<DeliverySlotDayModel>> getSlots();

  /// `POST /v1/delivery/select-address { addressId }` (customer only).
  Future<DeliverySelectionModel> selectAddress(String addressId);

  /// `POST /v1/delivery/select-branch { branchId }`.
  Future<DeliverySelectionModel> selectBranch(String branchId);
}

class DeliveryRemoteDataSourceImpl implements DeliveryRemoteDataSource {
  DeliveryRemoteDataSourceImpl(
    this._api,
    this._locale, {
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final ApiConsumer _api;
  final LocaleProvider _locale;

  /// Injectable so the cache window is testable.
  final DateTime Function() _now;

  /// Opening checkout twice in a row would otherwise re-read the same rows.
  static const Duration branchesTtl = Duration(minutes: 5);

  List<BranchModel>? _branches;
  String _branchesLanguage = '';
  DateTime? _branchesReadAt;

  static const String dataKey = 'data';
  static const String addressIdField = 'addressId';
  static const String branchIdField = 'branchId';
  static const String _branchesRoute = 'delivery/branches';
  static const String _slotsRoute = 'delivery/slots';
  static const String _selectRoute = 'delivery/select';

  @override
  Future<List<BranchModel>> getBranches() async {
    final language = _locale.languageCode;
    final cached = _branches;
    final readAt = _branchesReadAt;
    if (cached != null &&
        _branchesLanguage == language &&
        readAt != null &&
        _now().difference(readAt) < branchesTtl) {
      return cached;
    }
    final results = await _api.get(EndPoints.deliveryBranches);
    final branches = JsonRead.rows(
      ApiPayload.asMap(results, _branchesRoute)[dataKey],
      BranchModel.fromJson,
      logName: _branchesRoute,
    );
    _branches = branches;
    _branchesLanguage = language;
    _branchesReadAt = _now();
    return branches;
  }

  @override
  Future<List<DeliverySlotDayModel>> getSlots() async {
    final results = await _api.get(EndPoints.deliverySlots);
    return JsonRead.rows(
      ApiPayload.asMap(results, _slotsRoute)[dataKey],
      DeliverySlotDayModel.fromJson,
      logName: _slotsRoute,
    );
  }

  @override
  Future<DeliverySelectionModel> selectAddress(String addressId) async =>
      DeliverySelectionModel.fromJson(
        ApiPayload.asMap(
          await _api.post(
            EndPoints.deliverySelectAddress,
            body: <String, dynamic>{addressIdField: addressId},
          ),
          _selectRoute,
        ),
      );

  @override
  Future<DeliverySelectionModel> selectBranch(String branchId) async =>
      DeliverySelectionModel.fromJson(
        ApiPayload.asMap(
          await _api.post(
            EndPoints.deliverySelectBranch,
            body: <String, dynamic>{branchIdField: branchId},
          ),
          _selectRoute,
        ),
      );
}
