import 'package:flutter/widgets.dart';

import '../../../../core/motion/motion_widgets.dart';

/// One step of a sign-in sheet's entrance cascade: it rises and fades in
/// [index] steps into the page, the first ones while the sheet is still
/// rising ([leadIn] steps after the page opens).
class AuthCascadeItem extends StatelessWidget {
  const AuthCascadeItem({super.key, required this.index, required this.child});

  static const Duration stagger = Duration(milliseconds: 50);
  static const Offset rise = Offset(0, 0.2);
  static const int leadIn = 2;

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => StaggerEntrance(
    index: leadIn + index,
    stagger: stagger,
    beginOffset: rise,
    child: child,
  );
}
