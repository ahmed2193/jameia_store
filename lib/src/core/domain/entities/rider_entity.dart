import 'package:equatable/equatable.dart';

/// Delivery rider assigned to an order.
///
/// [rating] / [reviews] are deterministic offline stubs derived from [name]
/// (ported verbatim from the `Rider` DTO).
class RiderEntity extends Equatable {
  const RiderEntity({
    required this.name,
    required this.phone,
    required this.vehicle,
  });

  final String name;
  final String phone;

  /// motorbike | car.
  final String vehicle;

  int get _seed => name.hashCode.abs();

  /// Rider rating (4.6–4.9).
  double get rating =>
      double.parse((4.6 + (_seed % 4) / 10).toStringAsFixed(1));

  /// Rider review count.
  int get reviews => 120 + _seed % 1880;

  @override
  List<Object?> get props => [name, phone, vehicle];
}
