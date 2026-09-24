import '../../domain/entities/auth_customer_entity.dart';
import '../models/customer_model.dart';

/// `CustomerModel` (raw API shape) → `AuthCustomerEntity`.
extension CustomerMapper on CustomerModel {
  static const String _maleValue = 'male';
  static const String _femaleValue = 'female';

  AuthCustomerEntity toEntity() => AuthCustomerEntity(
    id: id,
    phone: phone,
    nameEn: nameEn,
    nameAr: nameAr,
    email: email,
    language: language,
    walletFils: wallet,
    loyaltyPoints: loyaltyPoints,
    isActive: status == CustomerModel.activeStatus,
    isPro: proActive,
    proExpiresAt: _date(proExpiresAt),
    dateOfBirth: _date(dateOfBirth),
    gender: switch (gender) {
      _maleValue => CustomerGender.male,
      _femaleValue => CustomerGender.female,
      _ => null,
    },
    householdSize: householdSize,
    marketingPush: marketingPush,
  );

  static DateTime? _date(String? raw) =>
      raw == null ? null : DateTime.tryParse(raw);
}

/// `AuthCustomerEntity` → `CustomerModel`, for the device copy of the
/// signed-in customer: the app-global session holds the entity, the device
/// stores the API shape (`CustomerModel.toJson`).
extension CustomerEntityMapper on AuthCustomerEntity {
  CustomerModel toModel() => CustomerModel(
    id: id,
    phone: phone,
    nameEn: nameEn,
    nameAr: nameAr,
    email: email,
    language: language,
    wallet: walletFils,
    loyaltyPoints: loyaltyPoints,
    status: isActive
        ? CustomerModel.activeStatus
        : CustomerModel.inactiveStatus,
    proActive: isPro,
    proExpiresAt: proExpiresAt?.toIso8601String(),
    dateOfBirth: switch (dateOfBirth) {
      final day? => CustomerModel.wireDate(day),
      null => null,
    },
    gender: gender?.wireValue,
    householdSize: householdSize,
    marketingPush: marketingPush,
  );
}

/// Wire value of a [CustomerGender] for `PATCH /v1/account/profile`.
extension CustomerGenderWire on CustomerGender {
  String get wireValue => switch (this) {
    CustomerGender.male => CustomerMapper._maleValue,
    CustomerGender.female => CustomerMapper._femaleValue,
  };
}
