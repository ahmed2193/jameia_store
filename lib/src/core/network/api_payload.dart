import '../error/exceptions.dart';

/// Shape guards for the envelope's `results`, shared by every remote
/// datasource so a malformed payload always fails the same way.
abstract final class ApiPayload {
  /// [results] as a JSON object, or a [ParsingException] naming the [route].
  static Map<String, dynamic> asMap(Object? results, String route) {
    if (results is Map) return results.cast<String, dynamic>();
    throw ParsingException('$route: unexpected payload ${results.runtimeType}');
  }
}
