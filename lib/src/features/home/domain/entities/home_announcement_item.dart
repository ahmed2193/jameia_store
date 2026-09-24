import 'package:equatable/equatable.dart';

import 'home_icon.dart';

/// One line of the announcement ticker above the home header ("Free delivery
/// on orders over 5.000 KWD"). [text] arrives already resolved for the request
/// language.
class HomeAnnouncementItem extends Equatable {
  const HomeAnnouncementItem({
    required this.id,
    required this.text,
    this.icon = const HomeIcon(),
  });

  final String id;
  final String text;
  final HomeIcon icon;

  @override
  List<Object?> get props => [id, text, icon];
}
