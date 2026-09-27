import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../config/di/service_locator.dart';
import '../cubit/assistant_buddy_cubit.dart';
import '../widgets/buddy/assistant_buddy_layer.dart';

/// The assistant's buddy floating over the main shell's tabs ([child]): a
/// mascot launcher in a bottom corner and, once in a while, a greeting that
/// drops in from the top with a few ways to start.
///
/// Not a route: the router hands it to the shell, which wraps its tab bodies
/// with it. [place] names the tab under it; [greetHere] / [launcherHere]
/// say what the buddy may do there.
class AssistantBuddyLayerPage extends StatelessWidget {
  const AssistantBuddyLayerPage({
    super.key,
    required this.place,
    required this.greetHere,
    required this.launcherHere,
    required this.child,
  });

  final String place;
  final bool greetHere;
  final bool launcherHere;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AssistantBuddyCubit>()..start(),
      child: AssistantBuddyLayer(
        place: place,
        greetHere: greetHere,
        launcherHere: launcherHere,
        child: child,
      ),
    );
  }
}
