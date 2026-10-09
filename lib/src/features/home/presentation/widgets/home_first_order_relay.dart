import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/first_order_bar_cubit.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';

/// Hands the home tab's first-order answer (`HomeState.firstOrderGift`) to
/// the bar on the shell's tab bar ([FirstOrderBarCubit]): once when the tab
/// mounts — its cubit may already know (the launch read the splash started),
/// and a new session's tab starts the bar over — then on every change.
/// Outside the main shell (a test, a stand-alone page) there is no bar to
/// tell.
class HomeFirstOrderRelay extends StatefulWidget {
  const HomeFirstOrderRelay({super.key, required this.child});

  final Widget child;

  @override
  State<HomeFirstOrderRelay> createState() => _HomeFirstOrderRelayState();
}

class _HomeFirstOrderRelayState extends State<HomeFirstOrderRelay> {
  @override
  void initState() {
    super.initState();
    // After this frame: telling the bar marks it for a rebuild, which must
    // not happen while the shell is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tell(context.read<HomeCubit>().state.firstOrderGift);
    });
  }

  void _tell(bool due) => context.read<FirstOrderBarCubit?>()?.show(due);

  @override
  Widget build(BuildContext context) {
    return BlocListener<HomeCubit, HomeState>(
      listenWhen: (previous, current) =>
          previous.firstOrderGift != current.firstOrderGift,
      listener: (context, state) => _tell(state.firstOrderGift),
      child: widget.child,
    );
  }
}
