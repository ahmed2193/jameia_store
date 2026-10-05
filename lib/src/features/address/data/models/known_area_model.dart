/// A district of Kuwait the app knows without the network: its names, its
/// governorate's names and roughly where its middle is (`KnownArea` once
/// mapped).
class KnownAreaModel {
  const KnownAreaModel({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.lat,
    required this.lng,
    this.governorateEn = '',
    this.governorateAr = '',
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final double lat;
  final double lng;
  final String governorateEn;
  final String governorateAr;
}
