import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../cubit/first_order_bar_cubit.dart';

/// The home tab's share of the main shell, around the whole shell ([child]:
/// the tab bodies and the tab bar): the [FirstOrderBarCubit] the home tab
/// feeds and the first-order bar on the tab bar reads. Lives as long as the
/// shell does.
class HomeShellScopePage extends StatelessWidget {
  const HomeShellScopePage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<FirstOrderBarCubit>(), child: child);
}
