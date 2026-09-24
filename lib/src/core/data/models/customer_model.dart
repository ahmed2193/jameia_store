import '../../error/exceptions.dart';

/// The public customer object the backend returns inside `results` of
/// `POST /v1/auth/verify-otp` (`results.customer`), `GET /v1/account/me` and
/// `PATCH /v1/account/profile`. Shared by the auth and account features, so
/// it lives in `core/data/models`.
///
/// Tolerant of both `_id` (Mongo) and `id`; keeps a bilingual `{ en, ar }`
/// name raw (a plain string — the documented shape — fills both) so the entity
/// can pick per locale. Dates stay ISO strings here; the mapper parses them.
///
/// Reference: https://api.jm3eia.store/docs (Account → `GET /v1/account/me`)
class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.phone,
    this.nameEn = '',
    this.nameAr = '',
    this.email = '',
    this.language = '',
    this.wallet = 0,
    this.loyaltyPoints = 0,
    this.status = activeStatus,
    this.proActive = false,
    this.proExpiresAt,
    this.dateOfBirth,
    this.gender,
    this.householdSize,
    this.marketingPush = true,
  });

  static const String mongoIdKey = '_id';
  static const String idKey = 'id';
  static const String phoneKey = 'phone';
  static const String nameKey = 'name';
  static const String emailKey = 'email';
  static const String languageKey = 'language';
  static const String walletKey = 'wallet';
  static const String loyaltyPointsKey = 'loyaltyPoints';
  static const String statusKey = 'status';
  static const String proKey = 'pro';
  static const String proActiveKey = 'active';
  static const String proExpiresAtKey = 'expiresAt';
  static const String dateOfBirthKey = 'dateOfBirth';
  static const String genderKey = 'gender';
  static const String householdSizeKey = 'householdSize';
  static const String marketingPushKey = 'marketingPush';
  static const String activeStatus = 'active';
  static const String inactiveStatus = 'inactive';
  static const String _englishKey = 'en';
  static const String _arabicKey = 'ar';
  static const int _dateLength = 10; // YYYY-MM-DD

  /// Throws [ParsingException] when the record carries no id — a customer
  /// without an identity is a broken payload, not an anonymous customer.
  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    final name = json[nameKey];
    final pro = json[proKey];
    final id = _string(json[mongoIdKey]) ?? _string(json[idKey]);
    if (id == null) throw const ParsingException('customer: id missing');
    return CustomerModel(
      id: id,
      phone: _string(json[phoneKey]) ?? '',
      nameEn: _localized(name, _englishKey),
      nameAr: _localized(name, _arabicKey),
      email: _string(json[emailKey]) ?? '',
      language: _string(json[languageKey]) ?? '',
      wallet: _int(json[walletKey]) ?? 0,
      loyaltyPoints: _int(json[loyaltyPointsKey]) ?? 0,
      status: _string(json[statusKey]) ?? activeStatus,
      proActive: pro is Map && pro[proActiveKey] == true,
      proExpiresAt: pro is Map ? _string(pro[proExpiresAtKey]) : null,
      dateOfBirth: _string(json[dateOfBirthKey]),
      gender: _string(json[genderKey]),
      householdSize: _int(json[householdSizeKey]),
      marketingPush: json[marketingPushKey] is bool
          ? json[marketingPushKey] as bool
          : true,
    );
  }

  final String id;
  final String phone;
  final String nameEn;
  final String nameAr;
  final String email;

  /// `en` | `ar` | `''` (never chosen).
  final String language;

  /// Balance in fils.
  final int wallet;
  final int loyaltyPoints;

  /// `active` | `inactive`.
  final String status;
  final bool proActive;

  /// ISO-8601 date-time, or `null`.
  final String? proExpiresAt;

  /// `YYYY-MM-DD`, or `null`.
  final String? dateOfBirth;

  /// `male` | `female` | `null`.
  final String? gender;
  final int? householdSize;
  final bool marketingPush;

  /// The API shape again (a `GET /v1/account/me` row), so what the device
  /// stores reads back through [CustomerModel.fromJson] unchanged. One name
  /// for both languages goes out as the plain string the backend sends.
  Map<String, dynamic> toJson() => <String, dynamic>{
    mongoIdKey: id,
    phoneKey: phone,
    nameKey: nameEn == nameAr
        ? nameEn
        : <String, dynamic>{_englishKey: nameEn, _arabicKey: nameAr},
    emailKey: email.isEmpty ? null : email,
    if (language.isNotEmpty) languageKey: language,
    walletKey: wallet,
    loyaltyPointsKey: loyaltyPoints,
    statusKey: status,
    proKey: <String, dynamic>{
      proActiveKey: proActive,
      proExpiresAtKey: proExpiresAt,
    },
    dateOfBirthKey: dateOfBirth,
    genderKey: gender,
    householdSizeKey: householdSize,
    marketingPushKey: marketingPush,
  };

  /// A calendar day as the API writes it (`dateOfBirth`: `YYYY-MM-DD`).
  static String wireDate(DateTime day) =>
      day.toIso8601String().substring(0, _dateLength);

  static String? _string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  static int? _int(Object? value) => value is num ? value.toInt() : null;

  /// A plain string applies to both languages; a map yields its language key.
  static String _localized(Object? value, String languageKey) {
    if (value is String) return value;
    if (value is Map) return _string(value[languageKey]) ?? '';
    return '';
  }
}
