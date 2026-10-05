import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';

/// One Google Places (New) autocomplete answer
/// (`suggestions[].placePrediction`): the place id, its name and address
/// lines, the stretches of the name that matched and, when the request named
/// an origin, how far it is.
class PlacePredictionModel {
  const PlacePredictionModel({
    required this.placeId,
    required this.mainText,
    this.secondaryText = '',
    this.mainMatches = const [],
    this.distanceMeters,
  });

  /// The `placePrediction` object. A prediction without a place id or a
  /// name cannot be picked: [ParsingException].
  factory PlacePredictionModel.fromJson(Map<String, dynamic> json) {
    final placeId = JsonRead.string(json[placeIdKey]);
    final format = JsonRead.object(json[structuredFormatKey]);
    final main = JsonRead.object(format?[mainTextKey]);
    final mainText =
        JsonRead.string(main?[textKey]) ??
        JsonRead.string(JsonRead.object(json[textKey])?[textKey]);
    if (placeId == null || mainText == null) {
      throw const ParsingException('place prediction without an id or name');
    }
    return PlacePredictionModel(
      placeId: placeId,
      mainText: mainText,
      secondaryText:
          JsonRead.string(
            JsonRead.object(format?[secondaryTextKey])?[textKey],
          ) ??
          '',
      mainMatches: _matches(main?[matchesKey]),
      distanceMeters: JsonRead.integer(json[distanceMetersKey]),
    );
  }

  /// The place predictions of an autocomplete reply; query predictions and
  /// broken rows are skipped.
  static List<PlacePredictionModel> listFromReply(Map<String, dynamic> reply) =>
      JsonRead.rows(reply[suggestionsKey], (row) {
        final prediction = JsonRead.object(row[placePredictionKey]);
        if (prediction == null) {
          throw const ParsingException('not a place prediction');
        }
        return PlacePredictionModel.fromJson(prediction);
      }, logName: logName);

  /// `matches[]` of a formattable text. Google leaves a zero offset out.
  static List<({int start, int end})> _matches(Object? json) => [
    for (final match in JsonRead.rows(json, (m) => m, logName: logName))
      if (JsonRead.integer(match[endOffsetKey]) case final end?)
        (start: JsonRead.integer(match[startOffsetKey]) ?? 0, end: end),
  ];

  static const String logName = 'places';
  static const String suggestionsKey = 'suggestions';
  static const String placePredictionKey = 'placePrediction';
  static const String placeIdKey = 'placeId';
  static const String textKey = 'text';
  static const String structuredFormatKey = 'structuredFormat';
  static const String mainTextKey = 'mainText';
  static const String secondaryTextKey = 'secondaryText';
  static const String matchesKey = 'matches';
  static const String startOffsetKey = 'startOffset';
  static const String endOffsetKey = 'endOffset';
  static const String distanceMetersKey = 'distanceMeters';

  final String placeId;
  final String mainText;
  final String secondaryText;
  final List<({int start, int end})> mainMatches;
  final int? distanceMeters;
}
