import '../../domain/entities/user_profile_entity.dart';
import '../models/catalog.dart';

/// `UserProfile` DTO → [UserProfileEntity].
extension UserProfileMapper on UserProfile {
  UserProfileEntity toEntity() => UserProfileEntity(
    id: id,
    name: name,
    phone: phone,
    avatar: avatar,
    deliveryCode: deliveryCode,
  );
}
