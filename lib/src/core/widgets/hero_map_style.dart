/// Map styles for `HeroMap.style` (Google Maps JSON styling).
///
/// Both share the Hero palette, so every map in the app reads as one: a
/// quiet, light base where the app's own pins and roads carry the colour —
/// land a warm off-white, parks the brand's light green
/// (`AppColors.brandLightBg`), highways a pale tint of the cape's amber,
/// water a soft blue, transit off.
///
/// * [brand] — a map that shows the app's own markers (the live rider map):
///   no place icons, no shops; road names stay, muted.
/// * [picker] — a map the customer finds their door on (the address
///   picker): the same look with the landmarks kept (their icons in grey,
///   names muted) and street names a step darker, since that is what the
///   customer reads to find their building.
abstract final class HeroMapStyle {
  static const String _base = '''
  {"elementType": "geometry", "stylers": [{"color": "#F5F6F3"}]},
  {"elementType": "labels.text.fill", "stylers": [{"color": "#6B7280"}]},
  {"elementType": "labels.text.stroke", "stylers": [{"color": "#FFFFFF"}]},
  {"featureType": "administrative.land_parcel", "stylers": [{"visibility": "off"}]},
  {"featureType": "landscape.man_made", "elementType": "geometry", "stylers": [{"color": "#EEF0EC"}]},
  {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#EEF1EC"}]},
  {"featureType": "poi.park", "elementType": "geometry", "stylers": [{"color": "#DCFCE7"}]},
  {"featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [{"color": "#15803D"}]},
  {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#FFFFFF"}]},
  {"featureType": "road", "elementType": "geometry.stroke", "stylers": [{"color": "#E5E7EB"}]},
  {"featureType": "road.highway", "elementType": "geometry.fill", "stylers": [{"color": "#FDF0C9"}]},
  {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#F4DC98"}]},
  {"featureType": "transit", "stylers": [{"visibility": "off"}]},
  {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#CFE8F3"}]},
  {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#7BA7BC"}]}''';

  static const String brand =
      '''
[
$_base,
  {"elementType": "labels.icon", "stylers": [{"visibility": "off"}]},
  {"featureType": "poi.business", "stylers": [{"visibility": "off"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#9CA3AF"}]}
]''';

  static const String picker =
      '''
[
$_base,
  {"elementType": "labels.icon", "stylers": [{"saturation": -100}, {"lightness": 20}]},
  {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#7C8590"}]},
  {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#4B5563"}]}
]''';
}
