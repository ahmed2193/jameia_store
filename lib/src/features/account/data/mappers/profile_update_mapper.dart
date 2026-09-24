import '../../../../core/data/mappers/customer_mapper.dart';
import '../../../../core/data/models/customer_model.dart';
import '../../domain/entities/profile_update.dart';

/// `ProfileUpdate` → the `PATCH /v1/account/profile` JSON body. Only changed
/// fields are sent; an empty email and every cleared value go out as `null`.
extension ProfileUpdateMapper on ProfileUpdate {
  static const String _nameKey = CustomerModel.nameKey;
  static const String _emailKey = CustomerModel.emailKey;
  static const String _languageKey = CustomerModel.languageKey;
  static const String _dateOfBirthKey = CustomerModel.dateOfBirthKey;
  static const String _genderKey = CustomerModel.genderKey;
  static const String _householdSizeKey = CustomerModel.householdSizeKey;

  Map<String, Object?> toBody() => <String, Object?>{
    if (name != null) _nameKey: name,
    if (email != null) _emailKey: email!.isEmpty ? null : email,
    if (language != null) _languageKey: language,
    if (dateOfBirth != null)
      _dateOfBirthKey: CustomerModel.wireDate(dateOfBirth!)
    else if (clearDateOfBirth)
      _dateOfBirthKey: null,
    if (gender != null)
      _genderKey: gender!.wireValue
    else if (clearGender)
      _genderKey: null,
    if (householdSize != null)
      _householdSizeKey: householdSize
    else if (clearHouseholdSize)
      _householdSizeKey: null,
  };
}
