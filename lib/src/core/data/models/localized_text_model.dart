import 'json_read.dart';

/// A `{ en, ar }` text as the order routes send names; a plain string is
/// taken for both languages.
class LocalizedTextModel {
  const LocalizedTextModel({this.en = '', this.ar = ''});

  static const String enKey = 'en';
  static const String arKey = 'ar';
  static const LocalizedTextModel empty = LocalizedTextModel();

  static LocalizedTextModel parse(Object? value) {
    if (value is String) return LocalizedTextModel(en: value, ar: value);
    final json = JsonRead.object(value);
    if (json == null) return empty;
    return LocalizedTextModel(
      en: JsonRead.string(json[enKey]) ?? '',
      ar: JsonRead.string(json[arKey]) ?? '',
    );
  }

  final String en;
  final String ar;
}
