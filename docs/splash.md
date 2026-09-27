# Splash — talabat-style brand intro

The launch experience follows talabat's pattern: a solid brand-colour screen
with the white mark in the middle (the native OS splash), then a short logo
animation on the same colour, then the app fades in. JameiaMart uses its own
colours: `AppColors.primary` green, white logo, yellow / orange accents.

## Flow

1. **Native splash** (Android 12+ SplashScreen API, Android ≤11 launch theme,
   iOS LaunchScreen.storyboard): green `#22C55E` + the white cart mark
   (`assets/splash/splash_mark.png`, 1152² read as 4× → a 288 dp/pt box,
   centred). It stays up until Flutter draws its first frame (`Localizations`
   defers that frame until the translations are loaded, so no blank frame).
2. **Flutter splash** (`features/splash`): its first frame repeats the native
   one exactly — the same cart, drawn by the same code, at the same size and
   place. It holds still until that frame is really on screen (first frame
   rasterized + `AppMotion.splashHandOffHold`, 600 ms fallback), then the
   chosen intro plays (~2 s). On Android 12+ `MainActivity` removes the system
   splash at once (`setOnExitAnimationListener { it.remove() }`); the default
   exit faded the icon out and the app in, which dimmed the logo for ~0.3 s.
3. **Hand-off**: `context.go(Routes.shell, extra: ShellEntrance.splash)`; the
   shell route then uses `JameiaFadeThroughPage` (fade + slight zoom) instead
   of the slide-up used for normal pushes.

## Versions

Pick one at build time with `--dart-define=SPLASH_VARIANT=<name>`
(`SplashVariant`, default `wordmark`):

| Name | What plays | Length |
|---|---|---|
| `wordmark` | The cart crouches and hops, then glides left and shrinks into the "J" of the name. The letters spring up one by one, the swoosh draws, the leaf grows on the "ı", the tagline fades in. White on green. | 2.0 s |
| `basket` | A bottle, an orange and some greens drop into the basket one by one, and the cart dips under each. Then the same assembly as `wordmark`. | 2.35 s |
| `burst` | The cart breathes in, then a white disc spreads out from it. As the disc passes, the logo turns into its full colours on white (the colour of the home screen). Then the name assembles. | 2.0 s |

Every version shares the same finish and colour layer:

- **Living colour**: a soft glow behind the logo (follows it into place) and
  three large blobs drifting slowly — lighter green, warm yellow, deep green.
  It fades in from the flat launch frame, so the hand-off stays invisible.
- **Landings**: a flat ring spreads on the ground when the cart lands (the
  hop, then the "J" slot), and a small confetti burst (dots, chips, leaves in
  yellow / white / mint / orange) pops out of the basket.
- **Letters** spring in tinted yellow and settle to white; the leaf is
  yellow; a light band sweeps across the finished name.
- **Touch**: a ring of colour where the finger lands, the glow leans towards
  the finger, and tapping the cart makes it hop (light haptic). Touch never
  changes how long the intro plays.

Reduced motion (`MediaQuery.disableAnimations`): the finished lockup shows at
once, touch effects are off, and the app opens after
`AppMotion.splashReducedHold` (700 ms).

## How it is built

- The logo is **vectors**: the cart mark (`SplashCartGeometry`), the letters
  "ameıaMart" as outlines of Nunito ExtraBold (`splash_wordmark_glyphs.dart`,
  generated; no font is shipped) and the leaf and swoosh
  (`SplashWordmarkGeometry`). It stays sharp at any size and each letter
  animates on its own.
- One `CustomPaint` (`SplashScenePainter`) and one `AnimationController`
  draw the whole scene. It repaints every frame without rebuilding any widget.
  A choreography (`SplashChoreography`) turns the clock into a `SplashFrame`,
  and the painter draws that frame (`SplashScenePainting`: background →
  ambient → rings → streaks → cart → name → confetti). The glow and blobs are
  radial gradients, not blurs, so they stay cheap. Touch reactions come from
  `SplashTouch`, whose ticker runs only while something still moves.
- The tagline (`splash.tagline`) is live, translated text, so it follows the
  app language and RTL. The logo itself is never mirrored.
- The status bar icons are light on green, and turn dark once the burst has
  covered the top of the screen.

## Regenerating

```sh
# after changing the cart mark: re-render the native image, then the platforms
flutter test tool/splash/render_native_splash_test.dart
dart run flutter_native_splash:create
# after changing the letters (see the script header for the font download)
node tool/splash/build_wordmark_glyphs.js nunito-800.ttf
```

`flutter_native_splash` keeps extra style items it did not write, so
`android:windowLightStatusBar=false` in `values-v31` / `values-night-v31`
(white status bar icons on green) survives a regenerate. iOS caches launch
screens: delete the app (or restart the simulator) to see a change.

## App icon

The launcher icon is the same cart mark as the splash (white cart, yellow
slats, brand green `#22C55E`), so the home screen, the OS splash and the
Flutter splash read as one brand. `tool/splash/render_app_icons_test.dart`
paints it with `SplashCartPainting` into `assets/app_icon/` (1024² generator
inputs, not bundled), and `flutter_launcher_icons` (config in `pubspec.yaml`)
writes the platform files:

| File | Used for |
|---|---|
| `icon_ios.png` | iOS app icon (opaque) and the legacy Android icon; green, soft glow, cart at 60 % width |
| `icon_foreground.png` | Android adaptive foreground on a `#22C55E` background; the cart's farthest point is 27 % of the canvas from the centre, inside the 66/108 dp safe circle (a test asserts it) |
| `icon_monochrome.png` | Android 13+ themed icon: one silhouette with the slats cut out |
| `icon_ios_dark.png` | iOS 18 dark icon (transparent) and, desaturated, the tinted icon |

```sh
flutter test tool/splash/render_app_icons_test.dart
dart run flutter_launcher_icons
# flutter_launcher_icons 0.14.4 bug: it rewrites this pbxproj setting to AppIcon; put it back
sed -i 's|ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = AppIcon;|ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;|' ios/Runner.xcodeproj/project.pbxproj
```

The generator does not delete old sizes: remove PNGs in
`AppIcon.appiconset` that `Contents.json` no longer lists (Xcode warns about
unassigned children). `assets/launcher/app_icon_square.png` is not the
launcher icon; it is the in-app logo (`JameiaAssets.appLogo`).

## What the old splash got wrong (fixed)

- Android ≤11 stretched a 1080×2339 photo with `gravity="fill"`, so it was
  distorted on any other screen shape.
- Android 12+ showed the wide wordmark at 72 % of the 1152 px icon, wider than
  the 768 px circle the system keeps, so its ends were clipped.
- The native frame (white, small wordmark tile) did not match the Flutter frame
  (full-screen photo), so the screen visibly jumped at hand-off.
- The tagline was English text baked into the image: no Arabic, no RTL.
- A 2.4 MB PNG was shipped three times (asset, Android, iOS) and decoded on the
  startup path (about 10 MB of pixels). The new mark is 15 KB and the Flutter
  side draws vectors.
- The shell slid up from the bottom over the splash like a sheet.
- Stale tokens (`splashMinDuration`, `splashImage`, `logoTile`) and no screen
  reader label.
