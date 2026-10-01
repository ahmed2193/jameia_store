import '../../../../core/data/models/json_read.dart';
import '../../../../core/error/exceptions.dart';
import 'courier_point_model.dart';

/// The store a delivery leaves from, as `GET /v1/delivery/branches` lists
/// it — only what the live map needs: `{ _id, name, lat, lng, phone }`. The id is
/// its identity; a branch without a pin has no [point].
class CourierStoreModel {
  const CourierStoreModel({
    required this.id,
    this.name = '',
    this.point,
    this.phone = '',
  });

  factory CourierStoreModel.fromJson(Map<String, dynamic> json) {
    final id = JsonRead.string(json[idKey]);
    if (id == null) throw const ParsingException('branch without an id');
    final lat = JsonRead.decimal(json[CourierPointModel.latKey]);
    final lng = JsonRead.decimal(json[CourierPointModel.lngKey]);
    return CourierStoreModel(
      id: id,
      name: JsonRead.string(json[nameKey]) ?? '',
      point: lat == null || lng == null
          ? null
          : CourierPointModel(lat: lat, lng: lng),
      phone: JsonRead.string(json[phoneKey]) ?? '',
    );
  }

  static const String idKey = '_id';
  static const String nameKey = 'name';
  static const String phoneKey = 'phone';

  final String id;

  /// The branch's name (in the request's language); empty when it has none.
  final String name;
  final CourierPointModel? point;

  /// The branch's phone line; empty when it has none.
  final String phone;
}
