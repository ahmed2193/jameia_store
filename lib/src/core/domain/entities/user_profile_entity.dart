import 'package:equatable/equatable.dart';

/// Signed-in user profile (home header, "Mine" tab, delivery-code cell).
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
