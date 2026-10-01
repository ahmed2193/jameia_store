/// Map styles for `HeroMap.style` (Google Maps JSON styling).
///
/// [brand] is the Hero look for a map that shows the app's own markers (the
/// live rider map): a quiet, light base so the route and the pins carry the
/// colour — shop and transit icons off, land a warm off-white, parks the
/// brand's light green (`AppColors.brandLightBg`), highways a pale tint of
/// the cape's amber, water a soft blue; road names stay, muted.
abstract final class HeroMapStyle {
  static const String brand = '''
[
  {"elementType": "geometry", "stylers": [{"color": "#F5F6F3"}]},
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#6B7280"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#FFFFFF"}]},
  {"featureType": "administrative.land_parcel", "stylers": [{"visibility": "off"}]},
  {"featureType": "landscape.man_made", "elementType": "geometry", "stylers": [{"color": "#EEF0EC"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#EEF1EC"}]},
  {"featureType": "poi.business", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#DCFCE7"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#15803D"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#FFFFFF"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#E5E7EB"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9CA3AF"}]},
  {"featureType": "road.highway", "elementType": "geometry.fill", "stylers": [{"color": "#FDF0C9"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#F4DC98"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#CFE8F3"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#7BA7BC"}]}
]''';
}
