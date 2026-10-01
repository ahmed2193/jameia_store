import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays [child] out at least as wide as it is tall, so a count pill keeps
/// its round ends however large the text grows: the height follows the
/// text, the width follows the height. With [square] both sides take the
/// longer one — one digit sits in a true circle even when its padding would
/// make it a little wider than tall. The child is laid out again, with the
/// held size as its floor, only when it came out of shape.
class AtLeastSquare extends SingleChildRenderObjectWidget {
  const AtLeastSquare({super.key, this.square = false, super.child});

  /// Width and height are made equal (the longer wins).
  final bool square;

  @override
  RenderAtLeastSquare createRenderObject(BuildContext context) =>
      RenderAtLeastSquare(square: square);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderAtLeastSquare renderObject,
  ) {
    renderObject.square = square;
  }
}

/// The render object of [AtLeastSquare].
class RenderAtLeastSquare extends RenderProxyBox {
  RenderAtLeastSquare({this._square = false});

  bool _square;
  bool get square => _square;
  set square(bool value) {
    if (value == _square) return;
    _square = value;
    markNeedsLayout();
  }

  Size _layoutChild(
    RenderBox child,
    BoxConstraints constraints,
    Size Function(RenderBox child, BoxConstraints constraints) layout,
  ) {
    final natural = layout(child, constraints);
    final side = _square
        ? math.max(natural.width, natural.height)
        : natural.height;
    final widen = natural.width < side;
    final heighten = _square && natural.height < side;
    if (!widen && !heighten) return natural;
    // A floor, not a tight size: tight constraints would make the child its
    // own relayout boundary, and a later change inside it (one more digit)
    // would never reach this box.
    return layout(
      child,
      constraints.copyWith(
        minWidth: widen
            ? math.min(
                math.max(constraints.minWidth, side),
                constraints.maxWidth,
              )
            : constraints.minWidth,
        minHeight: heighten
            ? math.min(
                math.max(constraints.minHeight, side),
                constraints.maxHeight,
              )
            : constraints.minHeight,
      ),
    );
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    size = _layoutChild(child, constraints, (box, limits) {
      box.layout(limits, parentUsesSize: true);
      return box.size;
    });
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return _layoutChild(
      child,
      constraints,
      (box, limits) => box.getDryLayout(limits),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    final child = this.child;
    if (child == null) return 0;
    return math.max(
      child.getMinIntrinsicWidth(height),
      child.getMinIntrinsicHeight(double.infinity),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    final child = this.child;
    if (child == null) return 0;
    return math.max(
      child.getMaxIntrinsicWidth(height),
      child.getMaxIntrinsicHeight(double.infinity),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final child = this.child;
    if (child == null) return 0;
    final height = child.getMinIntrinsicHeight(width);
    if (!_square) return height;
    return math.max(height, child.getMinIntrinsicWidth(double.infinity));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    final child = this.child;
    if (child == null) return 0;
    final height = child.getMaxIntrinsicHeight(width);
    if (!_square) return height;
    return math.max(height, child.getMaxIntrinsicWidth(double.infinity));
  }
}
