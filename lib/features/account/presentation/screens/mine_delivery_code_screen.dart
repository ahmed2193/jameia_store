import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion_widgets.dart';
import '../../../../core/responsive/app_size.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/delivery_code_cubit.dart';

/// KeeTa `mach_pro_sailor_c_mine_delivery_code` (Mine → Delivery code, v0.0.4) —
/// faithful 1:1 clone of the delivery-code editor.
///
/// KeeTa renders `renderVerifyCode` / `code_edit` / `code_check_pass|error`
/// backed by `getUserDeliveryCodeDetail` + `setUserDeliveryCode`. Here the code
/// is loaded through the account repository into a page-scoped
/// [DeliveryCodeCubit]; Save validates the 4-digit input and confirms in-place
/// (the dummy repository is read-only, so persistence is a demo no-op).
///
/// Sections (KeeTa order): big delivery-code display, explanation copy ("give it
/// to the rider — never share it via chat"), a 4-digit editor field, and a Save
/// button pinned at the bottom (`confirmBottomView`).
class MineDeliveryCodeScreen extends StatelessWidget {
  const MineDeliveryCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<DeliveryCodeCubit>(),
      child: const _DeliveryCodeView(),
    );
  }
}

// ── View ──────────────────────────────────────────────────────────────────────

class _DeliveryCodeView extends StatelessWidget {
  const _DeliveryCodeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mediumBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.primaryText,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(KeetaIcons.back, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'account.delivery_code'.tr(),
          style: AppTextStyles.headingLarge.copyWith(
            fontWeight: AppTextStyles.bold,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ContentClamp(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
            children: const [
              StaggerEntrance(index: 0, child: _CodeDisplayCard()),
              SizedBox(height: AppSpacing.s12),
              StaggerEntrance(index: 1, child: _ExplanationCard()),
              SizedBox(height: AppSpacing.s12),
              StaggerEntrance(index: 2, child: _CodeEditorCard()),
              SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const _SaveBar(),
    );
  }
}

// ── Big delivery-code display ─────────────────────────────────────────────────

class _CodeDisplayCard extends StatelessWidget {
  const _CodeDisplayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s24,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      child: Column(
        children: [
          const Icon(KeetaIcons.delivery, size: 32, color: AppColors.primary),
          const SizedBox(height: AppSpacing.s12),
          Text(
            'account.your_delivery_code'.tr(),
            style: AppTextStyles.subheadingLarge.copyWith(
              color: AppColors.primaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          // Live big code over a yellow highlight strip (bundle `dbee1f`:
          // #FFF6CB positioned absolutely behind the digits, r3, inset 12dp top).
          BlocBuilder<DeliveryCodeCubit, DeliveryCodeState>(
            buildWhen: (a, b) => a.savedCode != b.savedCode,
            builder: (context, state) => Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  top: AppSpacing.s12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.deliveryCodeBg,
                      borderRadius: BorderRadius.circular(AppRadius.r3),
                    ),
                  ),
                ),
                // The hero code pops in on first reveal and re-pops each time
                // the saved code changes.
                PopScale(
                  popKey: state.savedCode,
                  child: _CodeDigits(code: state.savedCode),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The persisted code rendered as spaced, boxed digits (the hero display).
class _CodeDigits extends StatelessWidget {
  const _CodeDigits({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    if (code.isEmpty) {
      return Text(
        '— — — —',
        style: AppTextStyles.displayLarge.copyWith(
          color: AppColors.disabledText,
          fontWeight: AppTextStyles.bold,
          letterSpacing: 10, // bundle `dd9dc2`
        ),
      );
    }
    final digits = code.split('');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final d in digits)
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.s6,
            ),
            child: Container(
              width: 60,
              height: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.smallBackground,
                borderRadius: BorderRadius.circular(AppRadius.r5),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                d,
                style: const TextStyle(
                  fontSize: AppSize.font40,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppTextStyles.fontFamily,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Explanation copy ──────────────────────────────────────────────────────────

class _ExplanationCard extends StatelessWidget {
  const _ExplanationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExplanationRow(
            icon: KeetaIcons.delivery,
            text: 'account.explain_give_code'.tr(),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ExplanationRow(
            icon: KeetaIcons.alert,
            text: 'account.explain_never_share'.tr(),
          ),
          const SizedBox(height: AppSpacing.s12),
          _ExplanationRow(
            icon: KeetaIcons.info,
            text: 'account.explain_change_when_idle'.tr(),
          ),
        ],
      ),
    );
  }
}

class _ExplanationRow extends StatelessWidget {
  const _ExplanationRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.secondaryText),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.captionLarge.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
        ),
      ],
    );
  }
}

// ── 4-digit editor field ──────────────────────────────────────────────────────

class _CodeEditorCard extends StatefulWidget {
  const _CodeEditorCard();

  @override
  State<_CodeEditorCard> createState() => _CodeEditorCardState();
}

class _CodeEditorCardState extends State<_CodeEditorCard> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Seed the field with the current code; the cubit loads it asynchronously,
    // so the BlocBuilder below resyncs the controller once the draft arrives.
    _controller.text = context.read<DeliveryCodeCubit>().state.draft;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.r3),
      ),
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
              color: AppColors.tertiaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          // The editable cells are a Stack over a hidden field, so the OS
          // keyboard drives a single source of truth (the cubit draft).
          BlocBuilder<DeliveryCodeCubit, DeliveryCodeState>(
            buildWhen: (a, b) => a.draft != b.draft || a.saved != b.saved,
            builder: (context, state) {
              // Keep the hidden controller in sync if state was reset elsewhere.
              if (_controller.text != state.draft) {
                _controller.value = TextEditingValue(
                  text: state.draft,
                  selection: TextSelection.collapsed(
                    offset: state.draft.length,
                  ),
                );
              }
              return _CellsField(
                controller: _controller,
                focusNode: _focusNode,
                draft: state.draft,
                showPass: state.saved,
                onChanged: context.read<DeliveryCodeCubit>().edit,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CellsField extends StatelessWidget {
  const _CellsField({
    required this.controller,
    required this.focusNode,
    required this.draft,
    required this.showPass,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String draft;
  final bool showPass;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Visible cells.
        Row(
          children: [
            for (var i = 0; i < DeliveryCodeState.codeLength; i++) ...[
              Expanded(
                child: _Cell(
                  value: i < draft.length ? draft[i] : '',
                  active: i == draft.length,
                  pass: showPass,
                ),
              ),
              if (i != DeliveryCodeState.codeLength - 1)
                const SizedBox(width: AppSpacing.s12),
            ],
          ],
        ),
        // Transparent capture field stretched over the cells.
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              maxLength: DeliveryCodeState.codeLength,
              showCursor: false,
              autofocus: false,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: onChanged,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.value, required this.active, required this.pass});
  final String value;
  final bool active;
  final bool pass;

  @override
  Widget build(BuildContext context) {
    // Bundle: active/focused cell `idba34` = solid black #000000; inactive
    // `bf94dd` = overlay-divider #00000014. Success is signalled by the snackbar,
    // not a colour change — so pass reuses the black active border.
    final borderColor = (active || pass)
        ? AppColors.primaryText
        : AppColors.overlayDivider;
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.smallBackground,
        borderRadius: BorderRadius.circular(AppRadius.r5),
        border: Border.all(color: borderColor, width: active || pass ? 2 : 1),
      ),
      child: Text(
        value,
        style: AppTextStyles.displaySmall.copyWith(
          fontWeight: AppTextStyles.bold,
        ),
      ),
    );
  }
}

// ── Save bar (confirmBottomView) ──────────────────────────────────────────────

class _SaveBar extends StatelessWidget {
  const _SaveBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s12),
        child: BlocConsumer<DeliveryCodeCubit, DeliveryCodeState>(
          listenWhen: (a, b) => !a.saved && b.saved,
          listener: (context, state) {
            FocusScope.of(context).unfocus();
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  content: Text('account.code_updated'.tr()),
                ),
              );
          },
          buildWhen: (a, b) => a.canSave != b.canSave,
          builder: (context, state) {
            return AppButton(
              label: 'account.save'.tr(),
              enabled: state.canSave,
              radius: AppRadius.r3,
              onPressed: context.read<DeliveryCodeCubit>().save,
            );
          },
        ),
      ),
    );
  }
}
