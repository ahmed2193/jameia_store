import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// `POST /v1/delivery/select-address` / `select-branch` → `results`.
class DeliverySelectionModel {
  const DeliverySelectionModel({
    required this.mode,
    required this.branchId,
    this.addressId,
    this.addressLabel = '',
    this.areaName = '',
    this.governorateName = '',
    this.branchName = '',
    this.address = '',
    this.zoneId,
    this.zoneName = '',
    this.deliveryFee = 0,
    this.minOrder = 0,
    this.etaMinutes,
  });

  static const String modeKey = 'mode';
  static const String addressIdKey = 'addressId';
  static const String addressLabelKey = 'addressLabel';
  static const String areaNameKey = 'areaName';
  static const String governorateNameKey = 'governorateName';
  static const String branchIdKey = 'branchId';
  static const String branchNameKey = 'branchName';
  static const String addressKey = 'address';
  static const String zoneIdKey = 'zoneId';
  static const String zoneNameKey = 'zoneName';
  static const String deliveryFeeKey = 'deliveryFee';
  static const String minOrderKey = 'minOrder';
  static const String etaMinutesKey = 'etaMinutes';

  factory DeliverySelectionModel.fromJson(Map<String, dynamic> json) {
    final mode = JsonRead.string(json[modeKey]);
    final branchId = JsonRead.string(json[branchIdKey]);
    if (mode == null || branchId == null) {
      throw const ParsingException('delivery selection: mode/branch missing');
    }
    return DeliverySelectionModel(
      mode: mode,
      branchId: branchId,
      addressId: JsonRead.string(json[addressIdKey]),
      addressLabel: JsonRead.string(json[addressLabelKey]) ?? '',
      areaName: JsonRead.string(json[areaNameKey]) ?? '',
      governorateName: JsonRead.string(json[governorateNameKey]) ?? '',
      branchName: JsonRead.string(json[branchNameKey]) ?? '',
      address: JsonRead.string(json[addressKey]) ?? '',
      zoneId: JsonRead.string(json[zoneIdKey]),
      zoneName: JsonRead.string(json[zoneNameKey]) ?? '',
      deliveryFee: JsonRead.integer(json[deliveryFeeKey]) ?? 0,
      minOrder: JsonRead.integer(json[minOrderKey]) ?? 0,
      etaMinutes: JsonRead.integer(json[etaMinutesKey]),
    );
  }

  /// `delivery` | `pickup`.
  final String mode;
  final String branchId;
  final String? addressId;
  final String addressLabel;
  final String areaName;
  final String governorateName;
  final String branchName;
  final String address;
  final String? zoneId;
  final String zoneName;
  final int deliveryFee;
  final int minOrder;
  final int? etaMinutes;
}
