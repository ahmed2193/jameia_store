import '../../domain/entities/place_spot.dart';
import '../../domain/entities/place_suggestion.dart';
import '../../domain/entities/text_match.dart';
import '../models/place_details_model.dart';
import '../models/place_prediction_model.dart';
import 'geo_point_model_mapper.dart';

extension PlacePredictionMapper on PlacePredictionModel {
  /// A Google answer: its point is looked up once picked.
  PlaceSuggestion toEntity() => PlaceSuggestion(
    id: placeId,
    title: mainText,
    subtitle: secondaryText,
    titleMatches: [
      for (final match in mainMatches) TextMatch(match.start, match.end),
    ],
    distanceMeters: distanceMeters,
    source: PlaceSource.google,
  );
}

extension PlacePredictionListMapper on List<PlacePredictionModel> {
  List<PlaceSuggestion> toEntities() => [
    for (final row in this) row.toEntity(),
  ];
}

extension PlaceDetailsMapper on PlaceDetailsModel {
  /// The picked [suggestion] at its point.
  PlaceSpot toSpot(PlaceSuggestion suggestion) =>
      PlaceSpot(location: location.toEntity(), title: suggestion.title);
}
