import 'package:equatable/equatable.dart';

/// Framework-free order-line entity.
///
/// Owned by the support feature (no reuse of the core `OrderItem` DTO). Carries
/// the raw bilingual name so presentation can render the label directly; the
/// locale-live `displayName` stays a presentation concern (unused here — the
/// help-center recent-order card reads the raw [name]).
class OrderItemEntity extends Equatable {
  const OrderItemEntity({
    required this.name,
    this.nameAr = '',
    required this.qty,
    required this.price,
  });

  final String name; // English / default
  final String nameAr; // Arabic counterpart
  final int qty;
  final double price;

  @override
  List<Object?> get props => [name, nameAr, qty, price];
}
