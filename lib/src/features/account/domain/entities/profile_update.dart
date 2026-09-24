import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';

/// The editable subset of the customer profile (`PATCH /v1/account/profile`):
/// name, email, language, date of birth, gender and household size. `null`
/// means "unchanged"; an empty [email] and the `clear…` flags clear a value on
/// the server (JSON `null`).
///
/// Reference: https://docs.jm3eia.store/developers/account.html
class ProfileUpdate extends Equatable {
  const ProfileUpdate({
    this.name,
    this.email,
    this.language,
    this.dateOfBirth,
    this.clearDateOfBirth = false,
    this.gender,
    this.clearGender = false,
    this.householdSize,
    this.clearHouseholdSize = false,
  });

  /// Backend limits (OpenAPI: `name` 1–120, `email` 3–120, `householdSize`
  /// 1–20, `dateOfBirth` `YYYY-MM-DD`).
  static const int maxNameLength = 120;
  static const int minEmailLength = 3;
  static const int maxEmailLength = 120;
  static const int minHouseholdSize = 1;
  static const int maxHouseholdSize = 20;

  /// The earliest birth year the form offers.
  static const int earliestBirthYear = 1900;

  static final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Only the fields that differ between [current] and the edited values, so
  /// an unchanged form sends nothing. A `null` date of birth, gender or
  /// household size the customer had a value for is a "clear".
  factory ProfileUpdate.diff({
    required AuthCustomerEntity current,
    required String name,
    required String email,
    required CustomerGender? gender,
    required DateTime? dateOfBirth,
    required int? householdSize,
  }) {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim();
    return ProfileUpdate(
      name: trimmedName == current.givenName ? null : trimmedName,
      email: trimmedEmail == current.email ? null : trimmedEmail,
      gender: gender == current.gender ? null : gender,
      clearGender: gender == null && current.gender != null,
      dateOfBirth: isSameDay(dateOfBirth, current.dateOfBirth)
          ? null
          : dateOfBirth,
      clearDateOfBirth: dateOfBirth == null && current.dateOfBirth != null,
      householdSize: householdSize == current.householdSize
          ? null
          : householdSize,
      clearHouseholdSize:
          householdSize == null && current.householdSize != null,
    );
  }

  final String? name;
  final String? email;

  /// `en` / `ar`.
  final String? language;
  final DateTime? dateOfBirth;

  /// Send `dateOfBirth: null` (the customer removed it).
  final bool clearDateOfBirth;
  final CustomerGender? gender;

  /// Send `gender: null` (the customer withdrew the value).
  final bool clearGender;
  final int? householdSize;

  /// Send `householdSize: null` (the customer removed it).
  final bool clearHouseholdSize;

  bool get isEmpty =>
      name == null &&
      email == null &&
      language == null &&
      dateOfBirth == null &&
      !clearDateOfBirth &&
      gender == null &&
      !clearGender &&
      householdSize == null &&
      !clearHouseholdSize;

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

  /// A birthday from [earliestBirthYear] up to [today] (never in the future).
  static bool isValidDateOfBirth(DateTime value, {required DateTime today}) =>
      value.year >= earliestBirthYear && !_day(value).isAfter(_day(today));

  static bool isValidHouseholdSize(int value) =>
      value >= minHouseholdSize && value <= maxHouseholdSize;

  /// Both unset, or the same calendar day (the time of day is ignored).
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return a == b;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime _day(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  List<Object?> get props => [
    name,
    email,
    language,
    dateOfBirth,
    clearDateOfBirth,
    gender,
    clearGender,
    householdSize,
    clearHouseholdSize,
  ];
}
