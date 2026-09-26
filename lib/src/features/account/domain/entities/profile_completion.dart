import 'package:equatable/equatable.dart';

import '../../../../core/domain/entities/auth_customer_entity.dart';
import 'profile_field.dart';
import 'profile_update.dart';

/// How much of the profile is filled in: every [ProfileField] counts the
/// same, a value only counts when the backend would accept it (a blank name
/// or a malformed email is still missing). [next] is the field the form asks
/// for first.
class ProfileCompletion extends Equatable {
  const ProfileCompletion(this.missing);

  /// The completion of a draft (or of a saved profile: pass its values).
  factory ProfileCompletion.of({
    required String name,
    required String email,
    required DateTime? dateOfBirth,
    required CustomerGender? gender,
    required int? householdSize,
  }) {
    final household = householdSize;
    bool isFilled(ProfileField field) => switch (field) {
      ProfileField.name => ProfileUpdate.isValidName(name),
      ProfileField.dateOfBirth => dateOfBirth != null,
      ProfileField.gender => gender != null,
      ProfileField.householdSize =>
        household != null && ProfileUpdate.isValidHouseholdSize(household),
      ProfileField.email => ProfileUpdate.isValidEmail(email),
    };
    return ProfileCompletion([
      for (final field in ProfileField.values)
        if (!isFilled(field)) field,
    ]);
  }

  static const int _percentScale = 100;

  /// The fields still empty, in the order the form asks for them.
  final List<ProfileField> missing;

  int get total => ProfileField.values.length;

  int get filled => total - missing.length;

  /// 0..1.
  double get ratio => filled / total;

  /// 0..100, rounded.
  int get percent => (ratio * _percentScale).round();

  bool get isComplete => missing.isEmpty;

  /// The field to fill in next; `null` once the profile is complete.
  ProfileField? get next => missing.isEmpty ? null : missing.first;

  @override
  List<Object?> get props => [missing];
}
