import 'package:flutter/widgets.dart';

import '../widgets/home_first_order_bar.dart';

/// The first-order free-delivery bar as the main shell places it, right on
/// its tab bar: on the tabs where it belongs ([here]: Home, Search, Mine —
/// never Cart, whose checkout bar stands there), while the customer is due
/// the gift. Needs [HomeShellScopePage] around the shell.
class FirstOrderBarLayerPage extends StatelessWidget {
  const FirstOrderBarLayerPage({super.key, required this.here});

  final bool here;

  @override
  Widget build(BuildContext context) => HomeFirstOrderBar(here: here);
}
