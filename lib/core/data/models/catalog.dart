/// Home-surface models: KingKong icon grid, banners, and the user profile.
library;

class KingKongItem {
  final String id;
  final String title;
  final String icon; // material icon name (mapped in widget)
  final String color; // hex

  const KingKongItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
  });

  factory KingKongItem.fromJson(Map<String, dynamic> j) => KingKongItem(
        id: j['id'] as String,
        title: j['title'] as String,
        icon: j['icon'] as String? ?? 'grid_view',
        color: j['color'] as String? ?? '#FFE41F',
      );
}

class HomeBanner {
  final String id;
  final String title;
  final String subtitle;
  final String image;
  final String bg; // hex

  const HomeBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.bg,
  });

  factory HomeBanner.fromJson(Map<String, dynamic> j) => HomeBanner(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        subtitle: j['subtitle'] as String? ?? '',
        image: j['image'] as String? ?? '',
        bg: j['bg'] as String? ?? '#FFE41F',
      );
}

class UserProfile {
  final String id;
  final String name;
  final String phone;
  final String avatar;
  final String deliveryCode;

  const UserProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatar,
    required this.deliveryCode,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        avatar: j['avatar'] as String? ?? '',
        deliveryCode: j['deliveryCode'] as String? ?? '',
      );
}
