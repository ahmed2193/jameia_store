import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';

/// The editable subset of the customer profile (`PATCH /v1/account/profile`).
/// `null` means "unchanged"; an empty [email] clears it on the server.
///
/// Reference: https://docs.jm3eia.store/developers/account.html
class ProfileUpdate extends Equatable {
  const ProfileUpdate({
    this.name,
    this.email,
    this.language,
    this.dateOfBirth,
    this.gender,
    this.clearGender = false,
    this.householdSize,
  });

  /// Backend limits (OpenAPI: `name` 1–120, `email` 3–120, `householdSize`
  /// 1–20).
  static const int maxNameLength = 120;
  static const int minEmailLength = 3;
  static const int maxEmailLength = 120;
  static const int minHouseholdSize = 1;
  static const int maxHouseholdSize = 20;

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Only the fields that differ between [current] and the edited values, so
  /// an unchanged form sends nothing.
  factory ProfileUpdate.diff({
    required AuthCustomerEntity current,
    required String name,
    required String email,
    required CustomerGender? gender,
  }) {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    return ProfileUpdate(
      name: trimmedName == current.anyName ? null : trimmedName,
      email: trimmedEmail == current.email ? null : trimmedEmail,
      gender: gender == current.gender ? null : gender,
      clearGender: gender == null && current.gender != null,
    );
  }

  final String? name;
  final String? email;

  /// `en` / `ar`.
  final String? language;
  final DateTime? dateOfBirth;
  final CustomerGender? gender;

  /// Send `gender: null` (the customer withdrew the value).
  final bool clearGender;
  final int? householdSize;

  bool get isEmpty =>
      name == null &&
      email == null &&
      language == null &&
      dateOfBirth == null &&
      gender == null &&
      !clearGender &&
      householdSize == null;

  static bool isValidName(String value) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty && trimmed.length <= maxNameLength;
  }

  static bool isValidEmail(String value) {
    final trimmed = value.trim();
    return trimmed.length >= minEmailLength &&
        trimmed.length <= maxEmailLength &&
        _emailPattern.hasMatch(trimmed);
  }

  @override
  List<Object?> get props => [
    name,
    email,
    language,
    dateOfBirth,
    gender,
    clearGender,
    householdSize,
  ];
}
