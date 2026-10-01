import '../../../../../core/design/hero_assets.dart';

/// Hero's public social profiles on About, each shown with its network's
/// official mark (`HeroAssets.brand*`, drawn untinted on a neutral tile).
enum AboutSocial {
  facebook(
    labelKey: 'settings.social_facebook',
    handle: 'facebook.com/Jameia',
    mark: HeroAssets.brandFacebook,
  ),
  instagram(
    labelKey: 'settings.social_instagram',
    handle: 'instagram.com/jameia.official',
    mark: HeroAssets.brandInstagram,
  ),
  x(
    labelKey: 'settings.social_x',
    handle: 'x.com/Jameia',
    mark: HeroAssets.brandX,
  );

  const AboutSocial({
    required this.labelKey,
    required this.handle,
    required this.mark,
  });

  final String labelKey;

  /// The public profile address (copied on tap).
  final String handle;

  /// The network's official mark (a `HeroAssets.brand*` path).
  final String mark;
}
