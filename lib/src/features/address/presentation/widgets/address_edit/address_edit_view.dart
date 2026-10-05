import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../config/routes/routes.dart';
import '../../../../../core/motion/motion.dart';
import '../../../domain/entities/map_destination.dart';
import '../../cubit/address_edit_cubit.dart';
import '../../cubit/address_picker_cubit.dart';
import 'address_details_stage.dart';
import 'address_map_stage.dart';
import 'address_stage_layers.dart';
import 'building_type_sheet.dart';
import 'map_picture.dart';

/// The address create / edit screen: the map picker and the address form
/// over ONE map that lives as long as the screen once made.
///
/// * A new address starts on the map. Confirm reads the pin, pictures the
///   map, asks once what kind of place it is, then the form comes over the
///   map (the forward push motion). Back from the form returns to the map;
///   back from the map leaves. A saved address that never had a pin starts
///   on the map the same way (its kind is known already).
/// * An address being edited starts on the form; its map is only made on
///   "Adjust pin". Confirm takes the form back with the new pin, back
///   returns to the form unchanged.
/// * Once the form covers the map, the map leaves the picture (it stays
///   alive for the way back), so the form's frames never draw it.
///
/// The form is built anew each time it comes up, so its fields show what
/// the map wrote into the draft meanwhile.
class AddressEditView extends StatefulWidget {
  const AddressEditView({
    super.key,
    required this.isEdit,
    required this.startsOnMap,
  });

  final bool isEdit;

  /// The map comes first: a new address, or one with no pin yet.
  final bool startsOnMap;

  @override
  State<AddressEditView> createState() => _AddressEditViewState();
}

class _AddressEditViewState extends State<AddressEditView>
    with SingleTickerProviderStateMixin {
  late final AddressPickerCubit _picker = context.read<AddressPickerCubit>();
  late final AddressEditCubit _edit = context.read<AddressEditCubit>();
  final MapPicture _picture = MapPicture();

  /// The building-type panel is up over the map: the search steps aside.
  final ValueNotifier<bool> _panelUp = ValueNotifier<bool>(false);

  /// The form over the map: 1 up, 0 away.
  late final AnimationController _form = AnimationController(
    vsync: this,
    value: widget.startsOnMap ? 0 : 1,
  )..addStatusListener(_formMoved);
  late final CurvedAnimation _formCurve = CurvedAnimation(
    parent: _form,
    curve: AppMotion.signature,
    reverseCurve: AppMotion.exit,
  );

  /// The form is up (or coming up), over the map.
  late bool _details = !widget.startsOnMap;

  /// The map came up from the form ("Adjust pin"): back returns to it.
  bool _adjusting = false;

  /// A Confirm is under way: a second tap asks nothing twice.
  bool _confirmBusy = false;

  /// What kind of place it is was answered (a new address asks once).
  late bool _typePicked = widget.isEdit;

  /// The map exists: from the start when it comes first, else from the
  /// first "Adjust pin".
  late bool _mapMade = widget.startsOnMap;

  /// The form fully covers the map: the map is out of the picture.
  late bool _mapAway = !widget.startsOnMap;

  /// Made once: the stage's moves never rebuild the native map.
  late final Widget _mapStage = AddressMapStage(
    onMapCreated: _picture.attach,
    onBack: _pop,
    onSearch: _searchTapped,
    onConfirm: _confirmTapped,
    panelUp: _panelUp,
  );

  /// Back leaves the screen from the stage it opened on.
  bool get _canLeave =>
      !_adjusting && (widget.startsOnMap ? !_details : _details);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _picker.languageChanged(context.locale.languageCode);
  }

  @override
  void dispose() {
    _formCurve.dispose();
    _form.dispose();
    _picture.dispose();
    _panelUp.dispose();
    super.dispose();
  }

  void _formMoved(AnimationStatus status) {
    if (!mounted) return;
    // Rebuilds the frame only: the map stage is one cached widget.
    setState(() => _mapAway = status.isCompleted);
  }

  void _show({required bool details, bool adjusting = false}) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _details = details;
      _adjusting = adjusting;
      if (!details) _mapMade = true;
    });
    final move = details
        ? _form.animateTo(
            1,
            duration: MotionGuard.duration(context, AppMotion.page),
          )
        : _form.animateBack(
            0,
            duration: MotionGuard.duration(context, AppMotion.medium),
          );
    unawaited(move);
  }

  void _back() {
    if (_edit.state.isSaving) return;
    if (_adjusting) {
      // The pin stays where it was confirmed; the map goes back there.
      _picker.returnTo(_edit.state.draft.pinnedPlace);
      _show(details: true);
      return;
    }
    if (_details && widget.startsOnMap) _showMap();
  }

  /// The map again, holding the pin as the form has it now: Confirm on the
  /// same spot keeps what the customer typed since, never the map's older
  /// words.
  void _showMap({bool adjusting = false}) {
    _picker.returnTo(_edit.state.draft.pinnedPlace);
    _show(details: false, adjusting: adjusting);
  }

  Future<void> _confirm() async {
    if (_confirmBusy) return;
    _confirmBusy = true;
    try {
      await _confirmPin();
    } finally {
      _confirmBusy = false;
    }
  }

  Future<void> _confirmPin() async {
    final place = await _picker.confirm();
    if (place == null || !mounted) return;
    // Pictured before anything moves over the map.
    await _picture.take();
    if (!mounted) return;
    if (!_typePicked) {
      _panelUp.value = true;
      final type = await showBuildingTypeSheet(context, overMap: true);
      if (!mounted) return;
      _panelUp.value = false;
      // Dismissed: the customer stays on the map.
      if (type == null) return;
      _typePicked = true;
      _edit.buildingTypeChanged(type);
    }
    _edit.pinConfirmed(place);
    _show(details: true);
  }

  Future<void> _changeType() async {
    final type = await showBuildingTypeSheet(
      context,
      selected: _edit.state.draft.buildingType,
    );
    if (type != null && mounted) _edit.buildingTypeChanged(type);
  }

  Future<void> _search() async {
    final destination = await context.push<MapDestination>(
      Routes.addressSearch,
      extra: _picker.state.target,
    );
    if (mounted && destination != null) _picker.goTo(destination);
  }

  void _adjustPin() => _showMap(adjusting: true);

  void _searchTapped() => unawaited(_search());

  void _confirmTapped() => unawaited(_confirm());

  void _changeTypeTapped() => unawaited(_changeType());

  void _pop() => unawaited(Navigator.maybePop(context));

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AddressStageLayers(
        mapStage: _mapStage,
        mapMade: _mapMade,
        mapAway: _mapAway,
        details: _details,
        formShown: _details || !_form.isDismissed,
        motion: _formCurve,
        form: AddressDetailsStage(
          isEdit: widget.isEdit,
          snapshot: _picture,
          onBack: _pop,
          onAdjustPin: _adjustPin,
          onChangeType: _changeTypeTapped,
        ),
      ),
    );
  }
}
