import 'package:equatable/equatable.dart';

/// The parts of an address the map can read for a pin and write into the
/// form: area, block, street and building number.
class AddressParts extends Equatable {
  const AddressParts({
    this.city = '',
    this.block = '',
    this.street = '',
    this.building = '',
  });

  static const AddressParts none = AddressParts();

  /// The area (the form's `city`).
  final String city;
  final String block;
  final String street;
  final String building;

  @override
  List<Object?> get props => [city, block, street, building];
}
