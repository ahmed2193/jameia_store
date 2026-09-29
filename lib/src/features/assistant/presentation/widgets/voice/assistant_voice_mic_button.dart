import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../cubit/assistant_voice_cubit.dart';
import '../../cubit/assistant_voice_state.dart';
import '../assistant_motion.dart';
import 'assistant_voice_drag.dart';
import 'assistant_voice_mic_face.dart';
import 'assistant_voice_mic_halo.dart';

/// The mic, WhatsApp style: press and hold to record — it grows under the
/// finger and follows it, toward the start of the line to cancel or up to
/// lock — and let go to send. Locked, it is the send button; while the
/// last words come in, a spinner. A screen reader's double tap records
/// hands-free (and sends from the locked button).
///
/// Raw pointer events, not a gesture detector: recording starts on touch
/// down, with no long-press delay and no gesture arena to lose.
class AssistantVoiceMicButton extends StatefulWidget {
  const AssistantVoiceMicButton({super.key, required this.drag});

  /// The finger's travel, shared with the hold bar and the lock.
  final ValueNotifier<AssistantVoiceDrag> drag;

  /// The held mic is this many times its size.
  static const double heldScale = AssistantMotion.holdScale;

  /// It grows from low in the button, mostly upward: the message box sits
  /// on the screen's bottom edge, which would cut a mic grown from its
  /// centre.
  static const Alignment _growFrom = Alignment(0, 0.8);

  @override
  State<AssistantVoiceMicButton> createState() =>
      _AssistantVoiceMicButtonState();
}

class _AssistantVoiceMicButtonState extends State<AssistantVoiceMicButton> {
  int? _pointer;
  Offset _origin = Offset.zero;
  AssistantVoicePhase _pressedIn = AssistantVoicePhase.idle;

  /// This press already cancelled or locked: the rest of it is ignored.
  bool _slid = false;

  AssistantVoiceCubit get _voice => context.read<AssistantVoiceCubit>();

  bool get _rtl => Directionality.of(context) == TextDirection.rtl;

  void _onDown(PointerDownEvent event) {
    if (!mounted || _pointer != null) return;
    final phase = _voice.state.phase;
    if (phase != AssistantVoicePhase.idle &&
        phase != AssistantVoicePhase.locked) {
      return;
    }
    _pointer = event.pointer;
    _origin = event.position;
    _pressedIn = phase;
    _slid = false;
    if (phase == AssistantVoicePhase.idle) {
      widget.drag.value = AssistantVoiceDrag.none;
      // The hold's tick now, before the recogniser opens: a vibration
      // while it listens would be heard (docs/motion §9.6 §2.9).
      Haptics.pick();
      _voice.hold(context.locale.languageCode);
    }
  }

  void _onMove(PointerMoveEvent event) {
    if (!mounted || event.pointer != _pointer) return;
    if (_pressedIn != AssistantVoicePhase.idle || _slid) return;
    final drag = AssistantVoiceDrag.of(event.position - _origin, rtl: _rtl);
    widget.drag.value = drag;
    if (drag.cancels) {
      _slid = true;
      _voice.discard();
    } else if (drag.locks) {
      _slid = true;
      _voice.lock();
    }
  }

  void _onUp(PointerUpEvent event) {
    if (!mounted || event.pointer != _pointer) return;
    _pointer = null;
    widget.drag.value = AssistantVoiceDrag.none;
    if (_slid) return;
    if (_pressedIn == AssistantVoicePhase.idle) {
      _voice.release();
    } else if (_isInside(event.localPosition)) {
      _voice.send();
    }
  }

  void _onCancel(PointerCancelEvent event) {
    if (!mounted || event.pointer != _pointer) return;
    _pointer = null;
    widget.drag.value = AssistantVoiceDrag.none;
    if (_pressedIn == AssistantVoicePhase.idle && !_slid) _voice.interrupt();
  }

  bool _isInside(Offset local) {
    final size = context.size;
    return size != null && (Offset.zero & size).contains(local);
  }

  @override
  Widget build(BuildContext context) {
    final phase = context.select<AssistantVoiceCubit, AssistantVoicePhase>(
      (cubit) => cubit.state.phase,
    );
    final held = phase == AssistantVoicePhase.holding;
    final locked = phase == AssistantVoicePhase.locked;
    // Reduced motion: the held mic does not grow, it only darkens.
    final reduced = MotionGuard.reduced(context);
    return Semantics(
      button: true,
      label: (locked ? 'assistant.send' : 'assistant.voice.record').tr(),
      hint: switch (phase) {
        AssistantVoicePhase.idle => 'assistant.voice.record_hint'.tr(),
        AssistantVoicePhase.locked => 'assistant.voice.a11y_locked'.tr(),
        _ => null,
      },
      onTap: switch (phase) {
        AssistantVoicePhase.idle => () => _voice.startHandsFree(
          context.locale.languageCode,
        ),
        AssistantVoicePhase.locked => _voice.send,
        _ => null,
      },
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onDown,
        onPointerMove: _onMove,
        onPointerUp: _onUp,
        onPointerCancel: _onCancel,
        // The mic follows the finger in a layer of its own: a move repaints
        // it alone.
        child: RepaintBoundary(
          child: ValueListenableBuilder<AssistantVoiceDrag>(
            valueListenable: widget.drag,
            builder: (context, drag, child) => Transform.translate(
              offset: held ? drag.micOffset(rtl: _rtl) : Offset.zero,
              child: child,
            ),
            child: SizedBox.square(
              dimension: AppSize.s48,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  if (held) const AssistantVoiceMicHalo(),
                  AnimatedScale(
                    scale: held && !reduced
                        ? AssistantVoiceMicButton.heldScale
                        : 1,
                    alignment: AssistantVoiceMicButton._growFrom,
                    duration: MotionGuard.duration(context, AppMotion.fast),
                    curve: AppMotion.emphasizedDecelerate,
                    child: AssistantVoiceMicFace(
                      phase: phase,
                      darkened: held && reduced,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
