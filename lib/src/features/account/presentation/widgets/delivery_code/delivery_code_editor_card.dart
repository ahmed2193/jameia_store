import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../config/theme/app_spacing.dart';
import '../../../../../config/theme/app_text_styles.dart';
import '../../cubit/delivery_code_cubit.dart';
import '../settings/settings_card.dart';
import 'delivery_code_cells.dart';

/// "Set a new code": the four-slot editor. The cubit's draft is the one
/// source of truth; the hidden field follows it (seeded when the saved code
/// arrives, rewritten to ASCII digits).
class DeliveryCodeEditorCard extends StatefulWidget {
  const DeliveryCodeEditorCard({super.key});

  @override
  State<DeliveryCodeEditorCard> createState() => _DeliveryCodeEditorCardState();
}

class _DeliveryCodeEditorCardState extends State<DeliveryCodeEditorCard> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _syncField(context.read<DeliveryCodeCubit>().state.draft);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _syncField(String draft) {
    if (_controller.text == draft) return;
    _controller.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'account.set_new_code'.tr(),
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: AppTextStyles.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'account.set_new_code_hint'.tr(),
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          BlocConsumer<DeliveryCodeCubit, DeliveryCodeState>(
            listenWhen: (previous, current) => previous.draft != current.draft,
            listener: (_, state) => _syncField(state.draft),
            buildWhen: (previous, current) =>
                previous.draft != current.draft ||
                previous.saved != current.saved,
            builder: (context, state) => ListenableBuilder(
              listenable: _focusNode,
              builder: (context, _) => DeliveryCodeCells(
                controller: _controller,
                focusNode: _focusNode,
                draft: state.draft,
                focused: _focusNode.hasFocus,
                saved: state.saved,
                onChanged: context.read<DeliveryCodeCubit>().edit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
