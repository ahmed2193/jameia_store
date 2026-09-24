import 'package:equatable/equatable.dart';

/// Where a promo card, promo strip, banner or marketing popup leads.
enum HomeLinkType { collection, category, brand, recipes, url, none }

/// A backend-configured link (`linkType` + `linkTarget`): a collection /
/// category / brand **slug**, the recipe list, or an external URL.
class HomeLink extends Equatable {
  const HomeLink({required this.type, this.target = ''});

  static const HomeLink none = HomeLink(type: HomeLinkType.none);

  final HomeLinkType type;

  /// Slug or URL; unused for [HomeLinkType.recipes] / [HomeLinkType.none].
  final String target;

  /// Whether a tap can go anywhere: the recipe list needs no target, every
  /// other kind does.
  bool get isNavigable => switch (type) {
    HomeLinkType.none => false,
    HomeLinkType.recipes => true,
    HomeLinkType.collection ||
    HomeLinkType.category ||
    HomeLinkType.brand ||
    HomeLinkType.url => target.isNotEmpty,
  };

  @override
  List<Object?> get props => [type, target];
}
