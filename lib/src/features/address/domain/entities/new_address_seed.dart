import 'package:equatable/equatable.dart';

/// What a new address starts from: whether it becomes the default one (a
/// customer's first address) and the signed-in customer's own number, the
/// one the courier calls unless the customer changes it.
class NewAddressSeed extends Equatable {
  const NewAddressSeed({this.isDefault = false, this.customerPhone = ''});

  final bool isDefault;

  /// As the account holds it (`+965XXXXXXXX`); empty when unknown.
  final String customerPhone;

  @override
  List<Object?> get props => [isDefault, customerPhone];
}
