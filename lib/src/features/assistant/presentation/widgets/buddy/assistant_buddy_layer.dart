import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/route_args/assistant_chat_args.dart';
import '../../../../../config/routes/routes.dart';
import '../../../../../core/motion/confetti_burst.dart';
import '../../../../../core/motion/fly_to_cart.dart';
import '../../../../../core/navigation/navigation.dart';
import '../../../../cart/presentation/cubit/cart_cubit.dart';
import '../../../../cart/presentation/cubit/cart_state.dart';
import '../../../domain/entities/assistant_starter.dart';
import '../../../domain/entities/assistant_thought.dart';
import '../../../domain/entities/assistant_thought_place.dart';
import '../../cubit/assistant_availability_cubit.dart';
import '../../cubit/assistant_buddy_cubit.dart';
import '../../cubit/assistant_buddy_scene.dart';
import '../../cubit/assistant_buddy_state.dart';
import 'assistant_buddy_greeting.dart';
import 'assistant_buddy_hide_sheet.dart';
import '../onboarding/assistant_onboarding_result.dart';
import '../onboarding/assistant_onboarding_sheet.dart';
import '../assistant_motion.dart';
import 'assistant_buddy_launcher.dart';
import 'buddy_motion_gate.dart';

/// Stacks the buddy over [child] and tells its cubit what goes on around
/// it: the tab, the store's switch, dialogs and pages on top, the keyboard,
/// a screen reader, scrolling and touches. The shell's content is never
/// rebuilt by the buddy — it is passed through untouched.
///
/// It holds the buddy's [BuddyMotionGate] too (docs/motion §9.6 §3.2): the
/// mascot stays still while the keyboard is up, while the customer scrolls,
/// while a page, sheet or dialog is over the shell or its tab is hidden and
/// while the app is away — and for `AssistantMotion.settle` after each —,
/// and holds a reaction while a thumbnail flies to the cart. The tab content
/// and the buddy paint on layers of their own, so a buddy frame never
/// repaints the screen under it.
///
/// It also presents the assistant's tour: on the launcher's first tap and
/// from the first greeting's invitation.
class AssistantBuddyLayer extends StatefulWidget {
  const AssistantBuddyLayer({
    super.key,
    required this.place,
    required this.greetHere,
    required this.launcherHere,
    this.thoughtPlace = AssistantThoughtPlace.elsewhere,
    required this.child,
  });

  final String place;
  final bool greetHere;
  final bool launcherHere;

  /// What the launcher's lines favour on this screen.
  final AssistantThoughtPlace thoughtPlace;
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
  bool _scrolling = false;

  /// Calm came back a moment ago (keyboard down, scroll ended, the shell
  /// in front again, the app back): the buddy waits out the settle.
  bool _settling = false;
  bool _wasCalm = true;
  Timer? _settle;

  /// The layer's route is on top and its tab shown (read with the
  /// dependencies, never in build).
  bool _inFront = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FlyToCart.inFlight.addListener(_onFlight);
    ConfettiBurst.playing.addListener(_onFlight);
  }

  void _onFlight() {
    if (mounted) setState(() {});
  }

  // A hidden tab (its tickers muted) is not in front either.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final inFront =
        (ModalRoute.isCurrentOf(context) ?? true) &&
        TickerMode.valuesOf(context).enabled;
    if (inFront == _inFront) return;
    _inFront = inFront;
    _updateCalm();
  }

  /// Whether the buddy may move now: calm, and past the settle.
  bool get _calm => _wasCalm && !_settling;

  /// Follows a change of what keeps the buddy still (called with the
  /// change, never from build); a change back to calm is held for the
  /// settle first.
  void _updateCalm() {
    final calm = _inFront && _resumed && !_keyboardOpen && !_scrolling;
    if (calm && !_wasCalm) {
      _settling = true;
      _settle?.cancel();
      _settle = Timer(AssistantMotion.settle, () {
        if (mounted) setState(() => _settling = false);
      });
    } else if (!calm) {
      _settle?.cancel();
      _settling = false;
    }
    _wasCalm = calm;
  }

  // The shell's Scaffold strips the keyboard inset from its body, so it is
  // read from the view itself.
  @override
  void didChangeMetrics() {
    final open = View.of(context).viewInsets.bottom > 0;
    if (open == _keyboardOpen) return;
    setState(() {
      _keyboardOpen = open;
      _updateCalm();
    });
  }

  // A backgrounded app keeps no mascot timers running, and coming back
  // after a while is a new visit (the launcher says hello again).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;
    if (resumed != _resumed) {
      setState(() {
        _resumed = resumed;
        _updateCalm();
      });
    }
    final buddy = context.read<AssistantBuddyCubit>();
    switch (state) {
      case AppLifecycleState.resumed:
        buddy.appResumed();
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        buddy.appPaused();
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
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
    final scrolling = notification.direction != ScrollDirection.idle;
    if (scrolling != _scrolling) {
      setState(() {
        _scrolling = scrolling;
        _updateCalm();
      });
    }
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

  /// A tap on the mascot, or on the line it is thinking ([asked]: the
  /// question that line puts to the chat, if any).
  void _open({AssistantStarter? asked}) {
    final buddy = context.read<AssistantBuddyCubit>();
    if (!buddy.state.onboarded) {
      unawaited(_tour(fromLauncher: true, asked: asked));
      return;
    }
    unawaited(buddy.launcherOpened());
    context.push(Routes.assistant, extra: _chatArgs(asked));
  }

  static AssistantChatArgs? _chatArgs(AssistantStarter? starter) =>
      starter == null
      ? null
      : AssistantChatArgs(initialPrompt: starter.promptKey.tr());

  /// The tour, from the launcher's first tap or the greeting's invitation.
  /// Off to the chat when the customer asks for it — or skips the tour
  /// they got by tapping the launcher to chat (with the question they
  /// tapped, [asked], unless the tour's end offered another). Otherwise the
  /// launcher says where it lives.
  Future<void> _tour({
    required bool fromLauncher,
    AssistantStarter? asked,
  }) async {
    final buddy = context.read<AssistantBuddyCubit>();
    unawaited(buddy.tourStarted());
    final result = await AssistantOnboardingSheet.show(context);
    if (!mounted) return;
    final chat = switch (result?.exit) {
      AssistantOnboardingExit.chat => true,
      AssistantOnboardingExit.skipped => fromLauncher,
      AssistantOnboardingExit.later || null => false,
    };
    buddy.tourEnded(coach: !chat);
    if (!chat) return;
    if (fromLauncher) unawaited(buddy.launcherOpened());
    context.push(Routes.assistant, extra: _chatArgs(result?.starter ?? asked));
  }

  Future<void> _offerHide() async {
    final buddy = context.read<AssistantBuddyCubit>();
    final hide = await showHeroBottomSheet<bool>(
      context,
      builder: (_) => const AssistantBuddyHideSheet(),
    );
    if (hide != true || !mounted) return;
    await buddy.hideLauncher();
    if (mounted) showHeroSnackBar(context, 'assistant.buddy_hidden'.tr());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FlyToCart.inFlight.removeListener(_onFlight);
    ConfettiBurst.playing.removeListener(_onFlight);
    _settle?.cancel();
    _touches.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inFront = _inFront;
    final calm = _calm;
    _report(
      AssistantBuddyScene(
        place: widget.place,
        available: context.select<AssistantAvailabilityCubit, bool>(
          (availability) => availability.state.isAvailable,
        ),
        greetHere: widget.greetHere,
        launcherHere: widget.launcherHere,
        inFront: inFront,
        keyboardOpen: _keyboardOpen,
        screenReader: MediaQuery.accessibleNavigationOf(context),
        hasCartItems: context.select<CartCubit, bool>(
          (cart) => cart.state.totalQty > 0,
        ),
        thoughtPlace: widget.thoughtPlace,
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
              child: RepaintBoundary(child: widget.child),
            ),
          ),
          Positioned.fill(
            child: BuddyMotionGate(
              mayMove: calm,
              holding: FlyToCart.inFlight.value || ConfettiBurst.playing.value,
              sensitive: !inFront,
              child: RepaintBoundary(
                child:
                    BlocSelector<
                      AssistantBuddyCubit,
                      AssistantBuddyState,
                      (bool, int, int, AssistantThought?)
                    >(
                      selector: (state) => (
                        state.launcherShown,
                        state.cheers,
                        state.visit,
                        state.thought,
                      ),
                      builder: (context, launcher) => AssistantBuddyLauncher(
                        shown: launcher.$1,
                        cheers: launcher.$2,
                        visit: launcher.$3,
                        thought: launcher.$4,
                        onThoughtSaid: context
                            .read<AssistantBuddyCubit>()
                            .thoughtSaid,
                        onThoughtDone: context
                            .read<AssistantBuddyCubit>()
                            .thoughtDone,
                        touches: _touches,
                        onOpen: _open,
                        onThoughtTap: (thought) =>
                            _open(asked: thought.starter),
                        onHide: _offerHide,
                      ),
                    ),
              ),
            ),
          ),
          PositionedDirectional(
            top: 0,
            start: 0,
            end: 0,
            child: RepaintBoundary(
              child: AssistantBuddyGreeting(
                onTour: () => unawaited(_tour(fromLauncher: false)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
