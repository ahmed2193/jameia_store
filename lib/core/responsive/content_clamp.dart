import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

/// Clamps content width on wide screens for readability.
/// The 720 dp default is a design-token, not a magic literal.
class ContentClamp extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  const ContentClamp({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMaxWidth,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
