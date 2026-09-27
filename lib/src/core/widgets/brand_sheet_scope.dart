import 'package:flutter/widgets.dart';

/// What a [BrandSheetScaffold]-style sheet tells the content it holds: how
/// far the header has folded for the keyboard — 0 open, 1 folded down to a
/// strip. A block that should make room too (an offer card over a form)
/// folds by the same value, in step with the header.
class BrandSheetScope extends InheritedWidget {
  const BrandSheetScope({super.key, required this.fold, required super.child});

  final Animation<double> fold;

  /// The fold of the nearest sheet; always open outside one.
  static Animation<double> foldOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BrandSheetScope>()?.fold ??
      kAlwaysDismissedAnimation;

  @override
  bool updateShouldNotify(BrandSheetScope oldWidget) =>
      oldWidget.fold != fold;
}
