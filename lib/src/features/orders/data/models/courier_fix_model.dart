import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';
import 'courier_point_model.dart';

/// One frame of the rider feed: `{ lat, lng, at, state, etaSeconds }`. The
/// position and the time are its identity (a fix nobody can place or date
/// is dropped by the caller); `state` is `assigning`, `to_store`,
/// `at_store`, `on_the_way` or `arrived` (anything else is kept as sent and
/// read as unknown).
class CourierFixModel {
  const CourierFixModel({
    required this.position,
    required this.at,
    this.state = '',
    this.etaSeconds,
  });

  factory CourierFixModel.fromJson(Map<String, dynamic> json) {
    final at = JsonRead.dateTime(json[atKey]);
    if (at == null) throw const ParsingException('courier fix without a time');
    return CourierFixModel(
      position: CourierPointModel.fromJson(json),
      at: at,
      state: JsonRead.string(json[stateKey]) ?? '',
      etaSeconds: JsonRead.integer(json[etaSecondsKey]),
    );
  }

  static const String atKey = 'at';
  static const String stateKey = 'state';
  static const String etaSecondsKey = 'etaSeconds';

  static const String assigningState = 'assigning';
  static const String toStoreState = 'to_store';
  static const String atStoreState = 'at_store';
  static const String onTheWayState = 'on_the_way';
  static const String arrivedState = 'arrived';

  final CourierPointModel position;
  final DateTime at;
  final String state;
  final int? etaSeconds;
}
