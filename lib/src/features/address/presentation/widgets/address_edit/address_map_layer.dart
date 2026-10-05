import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/domain/entities/geo_point_entity.dart';
import '../../../../../core/navigation/after_route_entrance.dart';
import '../../../../../core/widgets/hero_map.dart';
import '../../../../../core/widgets/hero_map_style.dart';
import '../../cubit/address_picker_cubit.dart';
import '../../cubit/address_picker_state.dart';

/// The picker's map: the Hero picker style, created once the page has come
/// in (a native map built mid-transition drops its frames) and the picker
/// knows where it opens ([AddressPickerState.opened]) — so a map with no pin
/// to show opens straight on the customer instead of flying there from a
/// city view. It tells the picker when it starts moving and where it
/// settles, and makes the camera moves the picker asks for — a glide, or a
/// jump under reduced motion. A move asked before the map exists waits for
/// it. Only the "you are here" dot rebuilds it; a native map made again
/// (the app's language changed) opens where the last one was.
class AddressMapLayer extends StatefulWidget {
  const AddressMapLayer({
    super.key,
    required this.padding,
    required this.onMapCreated,
  });

  /// Room the chrome takes at the top and the bottom.
  final EdgeInsets padding;
  final ValueChanged<GoogleMapController> onMapCreated;

  /// From a few countries away to a doorstep.
  static const MinMaxZoomPreference zoomRange = MinMaxZoomPreference(5, 20);

  @override
  State<AddressMapLayer> createState() => _AddressMapLayerState();
}

class _AddressMapLayerState extends State<AddressMapLayer> {
  late final AddressPickerCubit _picker = context.read<AddressPickerCubit>();

  GoogleMapController? _map;
  MapCameraMove? _waiting;

  /// Where the camera is now (kept without a rebuild); where the map opens
  /// until it moves.
  CameraPosition? _camera;

  static LatLng _latLng(GeoPointEntity point) => LatLng(point.lat, point.lng);

  void _created(GoogleMapController map) {
    _map = map;
    widget.onMapCreated(map);
    final waiting = _waiting;
    _waiting = null;
    if (waiting != null) {
      _move(waiting);
    } else {
      // The opening view counts as settled, should the map not say so.
      _settled();
    }
  }

  void _move(MapCameraMove move) {
    final map = _map;
    if (map == null) {
      _waiting = move;
      return;
    }
    final target = _latLng(move.target);
    final zoom = move.zoom;
    // Where the camera goes. A jump (every move under reduced motion)
    // settles without reporting its way on Android, so the map would
    // otherwise settle on the spot it left; a glide's frames overwrite it.
    _camera = CameraPosition(
      target: target,
      zoom: zoom ?? _camera?.zoom ?? _picker.state.openingZoom,
    );
    final update = zoom == null
        ? CameraUpdate.newLatLng(target)
        : CameraUpdate.newLatLngZoom(target, zoom);
    unawaited(
      move.glide ? map.glideTo(context, update) : map.moveCamera(update),
    );
  }

  void _settled() {
    final middle = _camera?.target;
    _picker.cameraIdle(
      middle == null
          ? _picker.state.target
          : GeoPointEntity(lat: middle.latitude, lng: middle.longitude),
    );
  }

  /// Where the map opens: the picker's spot, the first time it is made.
  CameraPosition _opening() {
    final camera = _camera;
    if (camera != null) return camera;
    final state = _picker.state;
    return _camera = CameraPosition(
      target: _latLng(state.target),
      zoom: state.openingZoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AddressPickerCubit, AddressPickerState>(
      listenWhen: (previous, next) =>
          next.camera != null && previous.camera != next.camera,
      listener: (context, state) => _move(state.camera!),
      child: AfterRouteEntrance(
        placeholder: _placeholder,
        child:
            BlocSelector<
              AddressPickerCubit,
              AddressPickerState,
              ({bool opened, bool showsMyLocation})
            >(
              selector: (state) => (
                opened: state.opened,
                showsMyLocation: state.showsMyLocation,
              ),
              builder: (context, map) {
                if (!map.opened) return _placeholder;
                final opening = _opening();
                return HeroMap(
                  target: opening.target,
                  zoom: opening.zoom,
                  style: HeroMapStyle.picker,
                  padding: widget.padding,
                  minMaxZoomPreference: AddressMapLayer.zoomRange,
                  myLocationEnabled: map.showsMyLocation,
                  onMapCreated: _created,
                  onCameraMoveStarted: _picker.cameraMoveStarted,
                  onCameraMove: (position) => _camera = position,
                  onCameraIdle: _settled,
                  onTap: (point) => _picker.mapTapped(
                    GeoPointEntity(lat: point.latitude, lng: point.longitude),
                  ),
                );
              },
            ),
      ),
    );
  }

  /// The ground before the map is made.
  static const Widget _placeholder = ColoredBox(
    color: AppColors.mediumBackground,
  );
}
