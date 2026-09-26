import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../../../../core/domain/entities/auth_customer_entity.dart';
import 'mine_avatar.dart';
import 'mine_header_metrics.dart';

/// The header avatar on its way from the centre of the open header ([dock]
/// 0) to the start of the collapsed bar at half size ([dock] 1). One
/// alignment drives both the placement and the scale origin, so the avatar
/// glides along a straight line and mirrors in RTL. Transform only — no
/// relayout while the page scrolls.
class MineDockingAvatar extends StatelessWidget {
  const MineDockingAvatar({
    super.key,
    required this.customer,
    required this.dock,
  });

  final AuthCustomerEntity? customer;
  final double dock;

  @override
  Widget build(BuildContext context) {
    final alignment = AlignmentDirectional.lerp(
      AlignmentDirectional.topCenter,
      AlignmentDirectional.topStart,
      dock,
    )!;
    return Align(
      alignment: alignment,
      child: Transform.scale(
        scale: lerpDouble(1, MineHeaderMetrics.avatarDockedScale, dock)!,
        alignment: alignment,
        child: MineAvatar(customer: customer, editBadgeScale: 1 - dock),
      ),
    );
  }
}
