import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/navigation/route_observer.dart';
import '../../cubit/assistant_voice_cubit.dart';

/// The microphone never outlives the chat on screen. Leaving the app, or
/// opening another page over the chat (the cart, a product, the history),
/// stops a recording — the words heard wait in the message box; the chat
/// closing drops it.
class AssistantVoiceLifecycle extends StatefulWidget {
  const AssistantVoiceLifecycle({super.key, required this.child});

  final Widget child;

  @override
  State<AssistantVoiceLifecycle> createState() =>
      _AssistantVoiceLifecycleState();
}

class _AssistantVoiceLifecycleState extends State<AssistantVoiceLifecycle>
    with RouteAware {
  late final AssistantVoiceCubit _voice;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _voice = context.read<AssistantVoiceCubit>();
    _lifecycle = AppLifecycleListener(onHide: _voice.interrupt);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is ModalRoute<void>) routeObserver.subscribe(this, route);
  }

  @override
  void didPushNext() => _voice.interrupt();

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _lifecycle.dispose();
    if (_voice.state.phase.isRecording) _voice.discard();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
