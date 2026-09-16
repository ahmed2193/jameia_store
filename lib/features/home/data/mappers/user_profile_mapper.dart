import '../../../../core/data/models/models.dart';
import '../../domain/entities/user_profile_entity.dart';

/// DTO → entity mapping for the user profile (no locale-live fields).
extension UserProfileMapper on UserProfile {
  UserProfileEntity toEntity() => UserProfileEntity(
        id: id,
        name: name,
        phone: phone,
        avatar: avatar,
        deliveryCode: deliveryCode,
      );
}
