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

/// Wire value of a [CustomerGender] for `PATCH /v1/account/profile`.
extension CustomerGenderWire on CustomerGender {
  String get wireValue => switch (this) {
    CustomerGender.male => CustomerMapper._maleValue,
    CustomerGender.female => CustomerMapper._femaleValue,
  };
}
