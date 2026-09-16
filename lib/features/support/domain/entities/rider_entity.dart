import 'package:equatable/equatable.dart';

/// Framework-free rider entity.
///
/// Owned by the support feature (no reuse of the core `Rider` DTO). Carries the
/// raw identity fields the IM chat surface renders; the dummy `rating`/`reviews`
/// are pure derivations of [name] (offline stubs), so they live on the entity
/// too — no framework coupling.
class RiderEntity extends Equatable {
  const RiderEntity({
    required this.name,
    required this.phone,
    required this.vehicle,
  });

  final String name;
  final String phone;
  final String vehicle; // motorbike | car

  int get _seed => name.hashCode.abs();

  /// Rider rating (4.6–4.9).
  double get rating =>
      double.parse((4.6 + (_seed % 4) / 10).toStringAsFixed(1));

  /// Rider review count.
  int get reviews => 120 + _seed % 1880;

  @override
  List<Object?> get props => [name, phone, vehicle];
}
