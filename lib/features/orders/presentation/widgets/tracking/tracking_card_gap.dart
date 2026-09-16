import 'package:flutter/material.dart';

/// Thin spacer — cards carry their own top/horizontal/bottom margins (6/9/9 dp),
/// so inter-card gaps are handled by `TrackingCard`'s own `margin`. This is a
/// no-op spacer kept for readability but actually does nothing visible.
class TrackingCardGap extends StatelessWidget {
  const TrackingCardGap({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
