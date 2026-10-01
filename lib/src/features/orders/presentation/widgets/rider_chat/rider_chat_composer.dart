import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../../../../core/design/hero_icons.dart';
import '../../../../../core/motion/haptics.dart';
import '../../../../../core/motion/motion.dart';
import '../../../../../core/motion/press_scale.dart';
import '../../../../../core/responsive/app_size.dart';
import '../../../domain/usecases/send_rider_message_usecase.dart';
import '../../cubit/rider_chat_cubit.dart';

/// Where the customer writes: a field that grows to a few lines, and a
/// round send button that lights up once there is something to send. The
/// words stay in the field until they are on their way.
class RiderChatComposer extends StatefulWidget {
  const RiderChatComposer({super.key, this.compact = false});

  /// Short on room (landscape, keyboard up): one line, a longer draft
  /// scrolls inside the box instead of growing it.
  final bool compact;

  @override
  State<RiderChatComposer> createState() => _RiderChatComposerState();
}

class _RiderChatComposerState extends State<RiderChatComposer> {
  final TextEditingController _text = TextEditingController();
  bool _ready = false;

  static const double _send = AppSize.s44;

  /// The button's hit box: a full 48 dp around the 44 dp disc.
  static const double _hit = AppSize.s48;
  static const double _glyph = AppSize.s20;
  static const int _maxLines = 4;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onText);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _onText() {
    final ready = _text.text.trim().isNotEmpty;
    if (ready != _ready) setState(() => _ready = ready);
  }

  /// The keyboard's send and the button's tap: nothing (not even the
  /// commit haptic) while the box is empty or a message is on its way.
  Future<void> _submit() async {
    if (!_ready || context.read<RiderChatCubit>().state.sending) return;
    Haptics.commit();
    final sent = await context.read<RiderChatCubit>().send(_text.text);
    if (sent && mounted) _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final sending = context.select<RiderChatCubit, bool>(
      (cubit) => cubit.state.sending,
    );
    final canSend = _ready && !sending;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.gutter,
        AppSpacing.s8,
        AppSpacing.s8,
        AppSpacing.s8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _text,
              minLines: 1,
              maxLines: widget.compact ? 1 : _maxLines,
              maxLength: SendRiderMessageUseCase.maxLength,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'orders.chat_hint'.tr(),
                counterText: '',
                filled: true,
                fillColor: AppColors.smallBackground,
                isDense: true,
                contentPadding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Semantics(
            button: true,
            enabled: canSend,
            label: 'orders.chat_send'.tr(),
            excludeSemantics: true,
            onTap: canSend ? _submit : null,
            child: PressScale(
              enabled: canSend,
              onTap: _submit,
              child: SizedBox.square(
                dimension: _hit,
                child: Center(
                  child: AnimatedContainer(
                    duration: MotionGuard.duration(context, AppMotion.fast),
                    curve: AppMotion.signature,
                    width: _send,
                    height: _send,
                    decoration: BoxDecoration(
                      color: canSend ? AppColors.primary : AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      HeroIcons.arrowUp,
                      size: _glyph,
                      color: AppColors.brandForeground,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
