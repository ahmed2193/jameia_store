import 'package:equatable/equatable.dart';

/// Framework-free placed-order entity returned by the checkout commit.
///
/// A thin, presentation-facing summary of the order the repository built and
/// persisted (the full core `KeetaOrder` — with items / rider — lives on in the
/// shared catalogue and is read back by the tracking feature via [id]). The
/// checkout screen only deep-links to tracking with [id]; the remaining scalars
/// (and the raw bilingual shop name) are carried so a richer success state can
/// resolve display live without touching a core DTO.
class KeetaOrderEntity extends Equatable {
  const KeetaOrderEntity({
    required this.id,
    required this.shopName,
    this.shopNameAr = '',
    this.shopId = '',
    required this.shopLogo,
    required this.status,
    required this.statusStep,
    required this.total,
    required this.date,
    this.dateAr = '',
  });

  final String id;
  final String shopName;
  final String shopNameAr;
  final String shopId;
  final String shopLogo;
  final String status;
  final int statusStep;
  final double total;
  final String date;
  final String dateAr;

  @override
  List<Object?> get props => [
        id,
        shopName,
        shopNameAr,
        shopId,
        shopLogo,
        status,
        statusStep,
        total,
        date,
        dateAr,
      ];
}
