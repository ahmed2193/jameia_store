import 'package:flutter/material.dart';

/// The canvas of an occasion tile: a pale top and a coloured hill rising
/// from its foot, with [badge] riding over it.
class HomeTileBackdrop extends StatelessWidget {
  const HomeTileBackdrop({
    super.key,
    required this.size,
    required this.base,
    required this.hill,
    this.badge,
  });

  /// Side of the (square) tile.
  final double size;
  final Color base;
  final Color hill;

  /// Drawn over the hill.
  final Widget? badge;

  /// How high the hill rises, and how round its crest is, as shares of the
  /// tile and of the hill.
  static const double _hillShare = 0.3;
  static const double _crestShare = 0.45;

  @override
  Widget build(BuildContext context) {
    final hillHeight = size * _hillShare;
    return SizedBox.square(
      dimension: size,
      child: ColoredBox(
        color: base,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PositionedDirectional(
              start: 0,
              end: 0,
              bottom: 0,
              height: hillHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: hill,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.elliptical(size / 2, hillHeight * _crestShare),
                  ),
                ),
              ),
            ),
            ?badge,
          ],
        ),
      ),
    );
  }
}
