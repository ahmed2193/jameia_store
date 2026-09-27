import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import '../../cubit/assistant_availability_cubit.dart';
import '../../cubit/assistant_buddy_cubit.dart';
import '../../cubit/assistant_buddy_scene.dart';
import '../../cubit/assistant_buddy_state.dart';
import 'assistant_buddy_greeting.dart';
import 'assistant_buddy_hide_sheet.dart';
import 'assistant_buddy_launcher.dart';

/// Stacks the buddy over [child] and tells its cubit what goes on around
/// it: the tab, the store's switch, dialogs and pages on top, the keyboard,
/// a screen reader, scrolling and touches. The shell's content is never
/// rebuilt by the buddy — it is passed through untouched.
class AssistantBuddyLayer extends StatefulWidget {
  const AssistantBuddyLayer({
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
  State<AssistantBuddyLayer> createState() => _AssistantBuddyLayerState();
}

class _AssistantBuddyLayerState extends State<AssistantBuddyLayer>
    with WidgetsBindingObserver {
  /// Where the last finger went down (global), for the mascot to glance at.
  final ValueNotifier<Offset?> _touches = ValueNotifier<Offset?>(null);

  AssistantBuddyScene? _reported;
  bool _keyboardOpen = false;
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // The shell's Scaffold strips the keyboard inset from its body, so it is
  // read from the view itself.
  @override
  void didChangeMetrics() {
    final open = View.of(context).viewInsets.bottom > 0;
    if (open != _keyboardOpen) setState(() => _keyboardOpen = open);
  }

  // A backgrounded app keeps no mascot timers running.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;
    if (resumed != _resumed) setState(() => _resumed = resumed);
  }

  /// Hands the scene to the cubit after the frame (never mid-build).
  void _report(AssistantBuddyScene scene) {
    if (scene == _reported) return;
    _reported = scene;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AssistantBuddyCubit>().setScene(scene);
    });
  }

  bool _onScroll(UserScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final buddy = context.read<AssistantBuddyCubit>();
    switch (notification.direction) {
      case ScrollDirection.reverse:
        buddy.scrollStarted(towardsEnd: true);
      case ScrollDirection.forward:
        buddy.scrollStarted(towardsEnd: false);
      case ScrollDirection.idle:
        buddy.scrollStopped();
    }
    return false;
  }

  void _onPointerDown(PointerDownEvent event) {
    _touches.value = event.position;
    context.read<AssistantBuddyCubit>().touched();
  }

  void _open() {
    context.read<AssistantBuddyCubit>().launcherOpened();
    context.push(Routes.assistant);
  }

  Future<void> _offerHide() async {
    final buddy = context.read<AssistantBuddyCubit>();
    final hide = await showJameiaBottomSheet<bool>(
      context,
      builder: (_) => const AssistantBuddyHideSheet(),
    );
    if (hide != true || !mounted) return;
    await buddy.hideLauncher();
    if (mounted) showJameiaSnackBar(context, 'assistant.buddy_hidden'.tr());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _touches.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _report(
      AssistantBuddyScene(
        place: widget.place,
        available: context.select<AssistantAvailabilityCubit, bool>(
          (availability) => availability.state.isAvailable,
        ),
        greetHere: widget.greetHere,
        launcherHere: widget.launcherHere,
        inFront: ModalRoute.isCurrentOf(context) ?? true,
        keyboardOpen: _keyboardOpen,
        screenReader: MediaQuery.accessibleNavigationOf(context),
        hasCartItems: context.select<CartCubit, bool>(
          (cart) => cart.state.totalQty > 0,
        ),
      ),
    );
    return BlocListener<CartCubit, CartState>(
      // Something went into the cart: the mascot hops for it.
      listenWhen: (previous, current) => current.totalQty > previous.totalQty,
      listener: (context, _) => context.read<AssistantBuddyCubit>().cheer(),
      child: Stack(
        children: [
          NotificationListener<UserScrollNotification>(
            onNotification: _onScroll,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _onPointerDown,
              child: widget.child,
            ),
          ),
          Positioned.fill(
            child:
                BlocSelector<
                  AssistantBuddyCubit,
                  AssistantBuddyState,
                  (bool, int)
                >(
                  selector: (state) => (state.launcherShown, state.cheers),
                  builder: (context, launcher) => AssistantBuddyLauncher(
                    shown: launcher.$1,
                    cheers: launcher.$2,
                    alive: _resumed,
                    touches: _touches,
                    onOpen: _open,
                    onHide: _offerHide,
                  ),
                ),
          ),
          const PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: AssistantBuddyGreeting(),
          ),
        ],
      ),
    );
  }
}
