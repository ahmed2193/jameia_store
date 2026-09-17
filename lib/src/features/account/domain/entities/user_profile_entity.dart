import 'package:equatable/equatable.dart';

/// Framework-free signed-in profile entity.
///
/// Owned by the account feature (no reuse of the core `UserProfile` DTO, no
/// `package:flutter/*` / `easy_localization` / `intl`). Carries the raw profile
/// fields the "Mine" surfaces render (header, delivery-code cell). The name is
/// carried raw; the empty-name fallback copy stays a presentation concern.
class UserProfileEntity extends Equatable {
  const UserProfileEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatar,
    required this.deliveryCode,
  });

  final String id;
  final String name;
  final String phone;
  final String avatar;
  final String deliveryCode;

  @override
  List<Object?> get props => [id, name, phone, avatar, deliveryCode];
}
