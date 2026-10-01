import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// A rider chat message:
/// `{ _id, from: "rider" | "customer", sentAt, text, translated: { en, ar } }`
/// — `translated` carries the words in each app language when the backend
/// translated them. Without an id, a side or a time it is no message.
class RiderChatMessageModel {
  const RiderChatMessageModel({
    required this.id,
    required this.from,
    required this.sentAt,
    required this.text,
    this.translated = const <String, String>{},
  });

  factory RiderChatMessageModel.fromJson(Map<String, dynamic> json) {
    final id = JsonRead.string(json[idKey]);
    final from = JsonRead.string(json[fromKey]);
    final sentAt = JsonRead.dateTime(json[sentAtKey]);
    if (id == null || from == null || sentAt == null) {
      throw const ParsingException('chat message without id, side or time');
    }
    final translated = JsonRead.object(json[translatedKey]);
    return RiderChatMessageModel(
      id: id,
      from: from,
      sentAt: sentAt,
      text: JsonRead.string(json[textKey]) ?? '',
      translated: <String, String>{
        if (translated != null)
          for (final entry in translated.entries)
            if (entry.value is String) entry.key: entry.value as String,
      },
    );
  }

  static const String idKey = '_id';
  static const String fromKey = 'from';
  static const String sentAtKey = 'sentAt';
  static const String textKey = 'text';
  static const String translatedKey = 'translated';
  static const String enKey = 'en';
  static const String arKey = 'ar';

  static const String riderSide = 'rider';
  static const String customerSide = 'customer';

  final String id;

  /// [riderSide] or [customerSide].
  final String from;
  final DateTime sentAt;
  final String text;
  final Map<String, String> translated;

  Map<String, dynamic> toJson() => <String, dynamic>{
    idKey: id,
    fromKey: from,
    sentAtKey: sentAt.toUtc().toIso8601String(),
    textKey: text,
    if (translated.isNotEmpty) translatedKey: translated,
  };
}
