import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/service_locator.dart';
import '../../../../core/data/keeta_repository.dart';
import '../../../../core/data/models/models.dart';
import '../../../../core/design/keeta_icons.dart';
import '../../../../core/motion/motion.dart';
import '../../../../core/responsive/content_clamp.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/core_widgets.dart';
import '../cubit/address_edit_cubit.dart';

/// KeeTa `mach_pro_sailor_c_address_select_page` (C-PAGE v0.0.136) clone — the
/// address create / edit form opened from the saved-address list.
///
/// 1:1 with the KeeTa reference section order: styled map header with a fixed
/// centre pin + a "use current location" chip, a POI search field, the
/// home/office/other label picker, the building/door/floor + recipient + phone +
/// note form, a drop-off ("when can't reach you") option, and a sticky bottom
/// Save CTA. Editing an existing address pre-fills the form when a [KeetaAddress]
/// is passed as the route argument.
class AddressEditScreen extends StatelessWidget {
  const AddressEditScreen({super.key, this.address});

  /// The address being edited; `null` for "Add new address".
  final KeetaAddress? address;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AddressEditCubit(sl<KeetaRepository>(), initial: address),
      child: _AddressEditView(isEdit: address != null),
    );
  }
}

class _AddressEditView extends StatefulWidget {
  const _AddressEditView({required this.isEdit});
  final bool isEdit;

  @override
  State<_AddressEditView> createState() => _AddressEditViewState();
}

class _AddressEditViewState extends State<_AddressEditView> {
  late final TextEditingController _poi;
  late final TextEditingController _building;
  late final TextEditingController _door;
  late final TextEditingController _floor;
  late final TextEditingController _recipient;
  late final TextEditingController _phone;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final s = context.read<AddressEditCubit>().state;
    _poi = TextEditingController(text: s.poi);
    _building = TextEditingController(text: s.building);
    _door = TextEditingController(text: s.door);
    _floor = TextEditingController(text: s.floor);
    _recipient = TextEditingController(text: s.recipient);
    _phone = TextEditingController(text: s.phone);
    _note = TextEditingController(text: s.note);
  }

  @override
  void dispose() {
    _poi.dispose();
    _building.dispose();
    _door.dispose();
    _floor.dispose();
    _recipient.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    final cubit = context.read<AddressEditCubit>();
    final saved = cubit.save(
      poi: _poi.text,
      building: _building.text,
      door: _door.text,
      floor: _floor.text,
      recipient: _recipient.text,
      phone: _phone.text,
      note: _note.text,
    );
    Navigator.pop(context, saved);
  }

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
          widget.isEdit ? 'Edit address' : 'Add new address',
          style:
              AppTextStyles.headingLarge.copyWith(fontWeight: AppTextStyles.bold),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ContentClamp(
          child: ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.s24),
            children: [
              const _MapHeader(),
              _PoiSearchField(controller: _poi),
              const SizedBox(height: AppSpacing.s8),
              const _LabelPicker(),
              const _AddressDetailCard(),
              _BuildingForm(
                building: _building,
                door: _door,
                floor: _floor,
              ),
              _RecipientForm(recipient: _recipient, phone: _phone),
              _NoteForm(note: _note),
              const _DropOffOption(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _SaveBar(onSave: _save),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map header — styled placeholder with fixed centre pin + current-location chip.
// (Real KeeTa renders an interactive map here; the clone is fully offline so a
//  branded static placeholder stands in.)
// ─────────────────────────────────────────────────────────────────────────────
class _MapHeader extends StatelessWidget {
  const _MapHeader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const _MapBackdrop(),
          // Centre pin (the address sits under the fixed map pin, KeeTa-style).
          const _CenterPin(),
          // "Use current location" chip, bottom-start over the map.
          PositionedDirectional(
            start: AppSpacing.s12,
            bottom: AppSpacing.s12,
            child: BlocSelector<AddressEditCubit, AddressEditState, String>(
              selector: (s) => s.area,
              builder: (context, area) => _CurrentLocationChip(area: area),
            ),
          ),
          // Recenter FAB, bottom-end.
          const PositionedDirectional(
            end: AppSpacing.s12,
            bottom: AppSpacing.s12,
            child: _RecenterButton(),
          ),
        ],
      ),
    );
  }
}

/// Soft grid + radial wash backdrop mimicking a zoomed map tile.
class _MapBackdrop extends StatelessWidget {
  const _MapBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          radius: 0.9,
          colors: [AppColors.brandLightBg, AppColors.smallBackground],
        ),
      ),
      child: CustomPaint(
        size: Size.infinite,
        painter: _MapGridPainter(),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  const _MapGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.divider
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    // A couple of faux "roads" for depth.
    final road = Paint()
      ..color = AppColors.white
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(0, size.height * 0.7),
      Offset(size.width, size.height * 0.35),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.3, 0),
      Offset(size.width * 0.62, size.height),
      road,
    );
  }

  @override
  bool shouldRepaint(covariant _MapGridPainter oldDelegate) => false;
}

/// Fixed centre pin + soft shadow ellipse beneath it.
class _CenterPin extends StatelessWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(KeetaIcons.location, size: 36, color: AppColors.primaryText),
        Container(
          width: 14,
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.overlayDivider,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        // Offset the column up so the pin tip lands at the exact centre.
        const SizedBox(height: 36),
      ],
    );
  }
}

/// "Current location" pill chip over the map.
class _CurrentLocationChip extends StatelessWidget {
  const _CurrentLocationChip({required this.area});
  final String area;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: const [
          BoxShadow(
              color: AppColors.overlayDivider,
              blurRadius: 8,
              offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(KeetaIcons.locationAlt,
              size: 14, color: AppColors.accent1),
          const SizedBox(width: AppSpacing.s6),
          Flexible(
            child: Text(
              area.isEmpty ? 'Locating…' : area,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionLarge
                  .copyWith(fontWeight: AppTextStyles.medium),
            ),
          ),
        ],
      ),
    );
  }
}

/// Recenter / my-location FAB on the map.
class _RecenterButton extends StatelessWidget {
  const _RecenterButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {},
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(KeetaIcons.locationOutline,
              size: 20, color: AppColors.primaryText),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POI search field — taps would open POI autocomplete in the real app.
// ─────────────────────────────────────────────────────────────────────────────
class _PoiSearchField extends StatelessWidget {
  const _PoiSearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Container(
        height: 44,
        padding:
            const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.smallBackground,
          borderRadius: BorderRadius.circular(AppRadius.r1),
        ),
        child: Row(
          children: [
            const Icon(KeetaIcons.search,
                size: 18, color: AppColors.tertiaryText),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.search,
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Search building, street or area',
                  hintStyle: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.tertiaryText),
                ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                if (value.text.isEmpty) return const SizedBox.shrink();
                return GestureDetector(
                  onTap: controller.clear,
                  child: const Icon(KeetaIcons.searchClear,
                      size: 16, color: AppColors.tertiaryText),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Label picker — Home / Office / Other chips.
// ─────────────────────────────────────────────────────────────────────────────
class _LabelPicker extends StatelessWidget {
  const _LabelPicker();

  static const _labels = ['Home', 'Office', 'Other'];
  static const _icons = [
    KeetaIcons.location,
    KeetaIcons.shop,
    KeetaIcons.address,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12, vertical: AppSpacing.s14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Save as',
              style: AppTextStyles.headingSmall
                  .copyWith(fontWeight: AppTextStyles.bold)),
          const SizedBox(height: AppSpacing.s10),
          BlocSelector<AddressEditCubit, AddressEditState, String>(
            selector: (s) => s.label,
            builder: (context, active) {
              final cubit = context.read<AddressEditCubit>();
              return Row(
                children: [
                  for (var i = 0; i < _labels.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: _LabelChip(
                        label: _labels[i],
                        icon: _icons[i],
                        selected: _labels[i] == active,
                        onTap: () => cubit.setLabel(_labels[i]),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primaryText : AppColors.secondaryText;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLightBg : AppColors.smallBackground,
          borderRadius: BorderRadius.circular(AppRadius.r4),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: fg),
            const SizedBox(width: AppSpacing.s6),
            Text(
              label,
              style: AppTextStyles.headingSmall.copyWith(
                color: fg,
                fontWeight:
                    selected ? AppTextStyles.bold : AppTextStyles.regular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selected-address summary card (reflects the map pin / POI search).
// ─────────────────────────────────────────────────────────────────────────────
class _AddressDetailCard extends StatelessWidget {
  const _AddressDetailCard();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AddressEditCubit, AddressEditState, String>(
      selector: (s) => s.line.isEmpty ? s.poi : s.line,
      builder: (context, line) {
        return Container(
          color: AppColors.white,
          margin: const EdgeInsets.only(top: AppSpacing.s8),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12, vertical: AppSpacing.s14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(KeetaIcons.storeLocation,
                  size: 20, color: AppColors.primaryText),
              const SizedBox(width: AppSpacing.s10),
              Expanded(
                child: Text(
                  line.isEmpty ? 'Pinned location' : line,
                  style: AppTextStyles.headingSmall
                      .copyWith(fontWeight: AppTextStyles.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable labelled field row + section wrapper.
// ─────────────────────────────────────────────────────────────────────────────
class _FormSection extends StatelessWidget {
  const _FormSection({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      margin: const EdgeInsets.only(top: AppSpacing.s8),
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.s12),
      child: Column(children: children),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.divider = true,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool divider;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: AppSpacing.s12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 84,
                child: Padding(
                  padding:
                      const EdgeInsetsDirectional.only(top: AppSpacing.s14),
                  child: Text(label,
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.secondaryText)),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  maxLines: maxLines,
                  minLines: 1,
                  style: AppTextStyles.bodyLarge,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.s14),
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: AppTextStyles.bodyLarge
                        .copyWith(color: AppColors.tertiaryText),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (divider)
          const Padding(
            padding: EdgeInsetsDirectional.only(end: AppSpacing.s12),
            child: ThinDivider(),
          ),
      ],
    );
  }
}

class _BuildingForm extends StatelessWidget {
  const _BuildingForm({
    required this.building,
    required this.door,
    required this.floor,
  });

  final TextEditingController building;
  final TextEditingController door;
  final TextEditingController floor;

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      children: [
        _FieldRow(
          label: 'Building',
          controller: building,
          hint: 'Building name / number',
        ),
        _FieldRow(
          label: 'Door',
          controller: door,
          hint: 'Door / unit number',
        ),
        _FieldRow(
          label: 'Floor',
          controller: floor,
          hint: 'Floor (optional)',
          divider: false,
        ),
      ],
    );
  }
}

class _RecipientForm extends StatelessWidget {
  const _RecipientForm({required this.recipient, required this.phone});
  final TextEditingController recipient;
  final TextEditingController phone;

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      children: [
        _FieldRow(
          label: 'Name',
          controller: recipient,
          hint: 'Recipient name',
        ),
        _FieldRow(
          label: 'Phone',
          controller: phone,
          hint: 'Mobile number',
          keyboardType: TextInputType.phone,
          divider: false,
        ),
      ],
    );
  }
}

class _NoteForm extends StatelessWidget {
  const _NoteForm({required this.note});
  final TextEditingController note;

  @override
  Widget build(BuildContext context) {
    return _FormSection(
      children: [
        _FieldRow(
          label: 'Note',
          controller: note,
          hint: 'Delivery note for the rider (optional)',
          maxLines: 3,
          divider: false,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drop-off option — hand-to-me vs leave-at-door (KeeTa "when can't reach you").
// ─────────────────────────────────────────────────────────────────────────────
class _DropOffOption extends StatelessWidget {
  const _DropOffOption();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      margin: const EdgeInsets.only(top: AppSpacing.s8),
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Drop-off option',
              style: AppTextStyles.headingSmall
                  .copyWith(fontWeight: AppTextStyles.bold)),
          const SizedBox(height: AppSpacing.s4),
          Text('How should the rider hand over your order?',
              style: AppTextStyles.captionLarge
                  .copyWith(color: AppColors.tertiaryText)),
          const SizedBox(height: AppSpacing.s10),
          BlocSelector<AddressEditCubit, AddressEditState, DropOff>(
            selector: (s) => s.dropOff,
            builder: (context, active) {
              final cubit = context.read<AddressEditCubit>();
              return Column(
                children: [
                  _DropOffTile(
                    icon: KeetaIcons.contactRider,
                    title: 'Hand it to me',
                    subtitle: 'The rider will deliver in person',
                    selected: active == DropOff.handToMe,
                    onTap: () => cubit.setDropOff(DropOff.handToMe),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  _DropOffTile(
                    icon: KeetaIcons.address,
                    title: 'Leave at the door',
                    subtitle: 'Drop at a designated spot',
                    selected: active == DropOff.leaveAtDoor,
                    onTap: () => cubit.setDropOff(DropOff.leaveAtDoor),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DropOffTile extends StatelessWidget {
  const _DropOffTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandLightBg : AppColors.smallBackground,
          borderRadius: BorderRadius.circular(AppRadius.r4),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: selected
                    ? AppColors.primaryText
                    : AppColors.secondaryText),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: AppTextStyles.headingSmall
                          .copyWith(fontWeight: AppTextStyles.bold)),
                  const SizedBox(height: AppSpacing.s2),
                  Text(subtitle,
                      style: AppTextStyles.captionLarge
                          .copyWith(color: AppColors.tertiaryText)),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppColors.primaryText : AppColors.disabledText,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky Save bar.
// ─────────────────────────────────────────────────────────────────────────────
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.onSave});
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.all(AppSpacing.s12),
      child: BlocSelector<AddressEditCubit, AddressEditState, bool>(
        selector: (s) => s.canSave,
        builder: (context, canSave) => AppButton(
          label: 'Save address',
          enabled: canSave,
          onPressed: onSave,
        ),
      ),
    );
  }
}
