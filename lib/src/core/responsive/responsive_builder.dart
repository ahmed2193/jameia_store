import 'package:flutter/widgets.dart';

import 'breakpoints.dart';

typedef ResponsiveWidgetBuilder =
    Widget Function(
      BuildContext context,
      Breakpoint breakpoint,
      Size size,
      TextScaler textScaler,
    );

class ResponsiveBuilder extends StatelessWidget {
  final ResponsiveWidgetBuilder builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final textScaler = MediaQuery.textScalerOf(context);
    final bp = Breakpoints.of(size.width);
    return builder(context, bp, size, textScaler);
  }
}
