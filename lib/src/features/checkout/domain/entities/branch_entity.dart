import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/catalog_product_entity.dart';
import '../../../../core/domain/entities/geo_point_entity.dart';

/// A store branch the customer can pick up from
/// (`GET /v1/delivery/branches`).
class BranchEntity extends Equatable {
  const BranchEntity({
    required this.id,
    required this.name,
    this.code = '',
    this.address = '',
    this.phone = '',
    this.location,
    this.supportsDelivery = false,
    this.supportsPickup = false,
    this.supportsExpress = false,
    this.minOrderFils = 0,
    this.etaMinutes,
  });

  final String id;
  final String name;
  final String code;
  final String address;
  final String phone;
  final GeoPointEntity? location;
  final bool supportsDelivery;
  final bool supportsPickup;
  final bool supportsExpress;
  final int minOrderFils;
  final int? etaMinutes;

  double get minOrderKd => minOrderFils / CatalogProductEntity.filsPerDinar;

  @override
  List<Object?> get props => [
    id,
    name,
    code,
    address,
    phone,
    location,
    supportsDelivery,
    supportsPickup,
    supportsExpress,
    minOrderFils,
    etaMinutes,
  ];
}
