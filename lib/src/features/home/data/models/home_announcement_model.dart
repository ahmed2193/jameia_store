import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';
import 'home_icon_model.dart';

/// `results.announcement` of `GET /v1/home`: the ticker above the header —
/// `null | { enabled, items: [{ id, text, icon }] }`.
class HomeAnnouncementModel {
  const HomeAnnouncementModel({
    this.enabled = false,
    this.items = const <HomeAnnouncementItemModel>[],
  });

  static const String enabledKey = 'enabled';
  static const String itemsKey = 'items';
  static const String _logName = 'HomeAnnouncementModel';

  /// A disabled, empty ticker when [raw] is `null` / not an object.
  factory HomeAnnouncementModel.fromJson(Object? raw) {
    final json = JsonRead.object(raw);
    if (json == null) return const HomeAnnouncementModel();
    return HomeAnnouncementModel(
      enabled: JsonRead.flag(json[enabledKey]),
      items: JsonRead.rows(
        json[itemsKey],
        HomeAnnouncementItemModel.fromJson,
        logName: _logName,
      ),
    );
  }

  final bool enabled;
  final List<HomeAnnouncementItemModel> items;
}

/// One ticker line. [text] arrives already resolved for `Accept-Language`.
class HomeAnnouncementItemModel {
  const HomeAnnouncementItemModel({
    required this.id,
    required this.text,
    this.icon,
  });

  static const String idKey = 'id';
  static const String textKey = 'text';
  static const String iconKey = 'icon';

  /// Throws [ParsingException] without text (an empty ticker line is noise).
  factory HomeAnnouncementItemModel.fromJson(Map<String, dynamic> json) {
    final text = JsonRead.string(json[textKey]);
    if (text == null) {
      throw const ParsingException('home announcement: text missing');
    }
    return HomeAnnouncementItemModel(
      id: JsonRead.string(json[idKey]) ?? text,
      text: text,
      icon: HomeIconModel.tryParse(json[iconKey]),
    );
  }

  final String id;
  final String text;
  final HomeIconModel? icon;
}
