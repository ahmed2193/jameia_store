import 'package:flutter/widgets.dart';

/// The two things a [HomeRevealScope] tells, each asked for on its own.
enum HomeRevealAspect { reveal, onScreen }

/// What a home block tells the pieces inside it: its reveal clock (0 → 1,
/// run once, the first time the block is seen) and whether the block is on
/// screen right now — so the pieces enter in step with the block, and their
/// looping touches rest while nobody can see them.
///
/// Outside any block (a widget test, a stand-alone preview) everything reads
/// as revealed and on screen. A piece that asks for one of the two is only
/// rebuilt when that one changes.
class HomeRevealScope extends InheritedModel<HomeRevealAspect> {
  const HomeRevealScope({
    super.key,
    required this.reveal,
    required this.onScreen,
    required super.child,
  });

  final Animation<double> reveal;
  final bool onScreen;

  /// The block's reveal clock; already complete outside a block.
  static Animation<double> revealOf(BuildContext context) =>
      InheritedModel.inheritFrom<HomeRevealScope>(
        context,
        aspect: HomeRevealAspect.reveal,
      )?.reveal ??
      kAlwaysCompleteAnimation;

  /// Whether the block is on screen, with its tab and route in front; true
  /// outside a block.
  static bool onScreenOf(BuildContext context) =>
      InheritedModel.inheritFrom<HomeRevealScope>(
        context,
        aspect: HomeRevealAspect.onScreen,
      )?.onScreen ??
      true;

  @override
  bool updateShouldNotify(HomeRevealScope oldWidget) =>
      oldWidget.reveal != reveal || oldWidget.onScreen != onScreen;

  @override
  bool updateShouldNotifyDependent(
    HomeRevealScope oldWidget,
    Set<HomeRevealAspect> dependencies,
  ) =>
      (dependencies.contains(HomeRevealAspect.reveal) &&
          oldWidget.reveal != reveal) ||
      (dependencies.contains(HomeRevealAspect.onScreen) &&
          oldWidget.onScreen != onScreen);
}
