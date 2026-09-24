import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/cart_entity.dart';
import '../../../../core/domain/entities/catalog_product_entity.dart';

/// What the server resolved after `POST /v1/delivery/select-address` or
/// `select-branch`: the serving branch / zone and the fee, minimum and ETA
/// the cart will use from now on.
class DeliverySelectionEntity extends Equatable {
  const DeliverySelectionEntity({
    required this.mode,
    this.addressId,
    this.addressLabel = '',
    this.areaName = '',
    this.governorateName = '',
    required this.branchId,
    this.branchName = '',
    this.branchAddress = '',
    this.zoneId,
    this.zoneName = '',
    this.deliveryFeeFils = 0,
    this.minOrderFils = 0,
    this.etaMinutes,
  });

  final FulfillmentMode mode;
  final String? addressId;
  final String addressLabel;
  final String areaName;
  final String governorateName;
  final String branchId;
  final String branchName;

  /// Pickup: where to collect.
  final String branchAddress;
  final String? zoneId;
  final String zoneName;
  final int deliveryFeeFils;
  final int minOrderFils;
  final int? etaMinutes;

  bool get isPickup => mode == FulfillmentMode.pickup;
  double get deliveryFeeKd =>
      deliveryFeeFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [
    mode,
    addressId,
    addressLabel,
    areaName,
    governorateName,
    branchId,
    branchName,
    branchAddress,
    zoneId,
    zoneName,
    deliveryFeeFils,
    minOrderFils,
    etaMinutes,
  ];
}
