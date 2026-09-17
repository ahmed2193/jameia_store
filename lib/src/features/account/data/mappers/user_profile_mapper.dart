import '../../../../core/data/models/models.dart';
import '../../domain/entities/user_profile_entity.dart';

/// DTO → entity mapping for the signed-in profile. Lives in the data layer, so
/// the framework coupling of the core [UserProfile] DTO never crosses into the
/// domain [UserProfileEntity], which stays plain Dart.
extension UserProfileMapper on UserProfile {
  UserProfileEntity toEntity() => UserProfileEntity(
    id: id,
    name: name,
    phone: phone,
    avatar: avatar,
    deliveryCode: deliveryCode,
  );
}

/// Convenience for mapping a whole list.
extension UserProfileListMapper on List<UserProfile> {
  List<UserProfileEntity> toEntities() => map((u) => u.toEntity()).toList();
}
