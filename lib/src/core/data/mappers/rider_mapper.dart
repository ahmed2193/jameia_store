import '../../domain/entities/rider_entity.dart';
import '../models/order.dart';

/// `Rider` DTO ⇄ [RiderEntity] (lossless both ways).
extension RiderMapper on Rider {
  RiderEntity toEntity() =>
      RiderEntity(name: name, phone: phone, vehicle: vehicle);
}

/// Reverse map — the rider flows back into `JameiaRepository.addOrder`.
extension RiderEntityMapper on RiderEntity {
  Rider toModel() => Rider(name: name, phone: phone, vehicle: vehicle);
}
