/// Pure bilingual value selection shared by every domain entity that carries
/// raw English + Arabic strings.
///
/// Mirrors the catalogue DTO rule (`localizedCatalogName` in
/// `core/data/models/shop.dart` and `_localized` in `catalog.dart`) exactly:
/// the Arabic value wins when [languageCode] starts with `ar` AND the Arabic
/// value is non-blank; otherwise the English value is returned (even when the
/// English value itself is empty).
///
/// Framework-free: the caller passes the active language code (in presentation
/// `context.locale.languageCode`), so no `intl` / `easy_localization` lookup
/// happens inside the domain.
String pickLocalized(
  String languageCode, {
  required String en,
  required String ar,
}) => languageCode.startsWith('ar') && ar.trim().isNotEmpty ? ar : en;
