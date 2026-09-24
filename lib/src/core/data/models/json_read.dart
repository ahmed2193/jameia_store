import 'dart:developer';

import '../../error/exceptions.dart';

/// Tolerant readers for the envelope's `results`, shared by the API DTOs so
/// every `fromJson` applies the same rules: `is` checks only, a wrong type
/// yields `null` (the DTO picks the default), a malformed list row is logged
/// and skipped instead of failing the page.
abstract final class JsonRead {
  /// A non-empty string, else `null`.
  static String? string(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  /// Numbers may arrive as int, double or a numeric string.
  static int? integer(Object? value) => switch (value) {
    int() => value,
    num() => value.toInt(),
    String() => int.tryParse(value),
    _ => null,
  };

  static double? decimal(Object? value) => switch (value) {
    num() => value.toDouble(),
    String() => double.tryParse(value),
    _ => null,
  };

  static bool flag(Object? value, {bool fallback = false}) =>
      value is bool ? value : fallback;

  /// A JSON object, else `null`.
  static Map<String, dynamic>? object(Object? value) =>
      value is Map ? value.cast<String, dynamic>() : null;

  /// The string items of a JSON array (anything else is dropped).
  static List<String> strings(Object? value) => value is List
      ? <String>[
          for (final item in value)
            if (item is String && item.isNotEmpty) item,
        ]
      : const <String>[];

  /// ISO-8601 date-time, else `null`.
  static DateTime? dateTime(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

  /// Parses every object row of [value] with [parse]; a row that is not an
  /// object or throws an [AppException] is logged under [logName] and skipped.
  /// A missing / non-array [value] is an empty list.
  static List<T> rows<T>(
    Object? value,
    T Function(Map<String, dynamic> json) parse, {
    required String logName,
  }) {
    if (value is! List) return <T>[];
    final parsed = <T>[];
    for (final raw in value) {
      if (raw is! Map) {
        log('dropped non-object row', name: logName);
        continue;
      }
      try {
        parsed.add(parse(raw.cast<String, dynamic>()));
      } on AppException catch (error) {
        log('dropped row: $error', name: logName);
      }
    }
    return parsed;
  }
}
