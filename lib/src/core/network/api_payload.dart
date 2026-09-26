import '../error/exceptions.dart';

/// Shape guards for the envelope's `results`, shared by every remote
/// datasource so a malformed payload always fails the same way.
abstract final class ApiPayload {
  /// The request body of a POST / PUT / PATCH / DELETE sent without one.
  /// Every request carries `Content-Type: application/json`, and the backend
  /// answers that content type with no body with `500 INTERNAL_ERROR`
  /// ("Body cannot be empty when content-type is set to 'application/json'"),
  /// so an empty write sends `{}` instead.
  static const Map<String, dynamic> emptyBody = <String, dynamic>{};

  /// [results] as a JSON object, or a [ParsingException] naming the [route].
  static Map<String, dynamic> asMap(Object? results, String route) {
    if (results is Map) return results.cast<String, dynamic>();
    throw ParsingException('$route: unexpected payload ${results.runtimeType}');
  }
}
