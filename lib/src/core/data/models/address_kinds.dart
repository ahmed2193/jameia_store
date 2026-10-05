// The kinds the offline address book ([HeroAddress]) stores with each
// address, by their numeric wire codes.

/// The building at the address.
enum StructType {
  apartment(2),
  house(3),
  office(4);

  const StructType(this.code);

  /// Hero numeric struct code (`regionDefaultStructType=2`).
  final int code;

  static StructType fromCode(int code) => StructType.values.firstWhere(
    (s) => s.code == code,
    orElse: () => StructType.apartment,
  );
}

/// The label the customer gave the address.
enum LabelType {
  home(0),
  work(1),
  hangout(2),
  faceDelivery(3),
  assignedPlace(4),
  other(5);

  const LabelType(this.code);

  final int code;

  static LabelType fromCode(int code) => LabelType.values.firstWhere(
    (l) => l.code == code,
    orElse: () => LabelType.home,
  );
}

/// How the order is handed over.
enum DropOff { handToMe, leaveAtSpot }
