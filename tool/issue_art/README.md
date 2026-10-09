# Hero issue states (moving state plates)

Source of the layered state illustrations in `assets/svg/state_*.svg`: the plates a screen
leads with when something went wrong (`StateIssue`: offline, store out of reach, timeout,
server trouble, maintenance, too many tries, signed out, no access, not found, unreadable
data, anything else) plus the closed-shop plate. Each plate acts its issue out once it is on
screen: the plug reaches for the socket and sparks, the stopwatch hand goes round, the smoke
rises from the server, the no-entry sign swings …

```
node tool/issue_art/build.js                      # src/*.svg → assets/svg/ (base + parts)
node tool/issue_art/build.js --check              # checks only, writes nothing
node tool/issue_art/build.js --sheet out.png      # … + a contact sheet of every master at rest
```

Needs only Node; the sheet renders with `@resvg/resvg-js` from `tool/icons/node_modules`
(`npm ci` there once).

## One master, several layers

`src/<plate>.svg` is the whole sticker at rest (160 × 120). Every top-level
`<g id="part-NAME">` group is a part that moves; everything else is the still base.

- The base keeps the master's name: `state_server.svg`.
- Each part becomes `state_server_<name>.svg` (`-` → `_`), in the same 160 × 120 frame, so
  the layers stack exactly. Parts draw over the base in source order: no still shape may come
  after the first part.
- Every file gets a `HeroAssets` constant (`test/core/design/hero_assets_svg_test.dart` checks
  it) and every part is listed in `StateArtMotions` (`lib/src/core/widgets/state_art_motions.dart`)
  with its tracks: `KeyframeTrack`s for `turn` (degrees), `dx` / `dy` (plate units), `scale`,
  `opacity`, around a `pivot` in plate units.

## The sticker grammar (same as every Hero plate)

- Soft floor shadow `ellipse(80, 106, 46, 6)` black at 8 %, the 88 dp disc `circle(80, 58, 44)`
  in a light AppColors tint, the content around the Hero bag where it fits.
- Ink `#0B2E13` outlines, 3 wide (2–2.5 on small details), round caps and joins; light fills
  only inside ink; badges at `(116, 30)` r 13; sparkles `#FFEA52` in `#F99022`.
- AppColors hexes only, no text / image / style / filter / gradient, one decimal at most on
  coordinates, < 10 KB a file. `build.js` refuses anything else.

## The story rules

- One lap is `AppMotion.stateArtLap` (2.4 s): still for the first tenth (the plate's entrance),
  the story, then still for the last quarter. `AmbientLoop` plays as many laps as fit
  `AppMotion.ambientBudget` (two), only while the plate is on screen, and replays when it comes
  back.
- Every track starts and ends on the part as drawn (a turn may end on a symmetric quarter:
  the eight-tooth gear, the four-point sparkle, the stopwatch hand's full turn), so reduced
  motion, a screen reader, an off-screen plate or a spent budget all show the still sticker.
  A part that only shows mid-story (the spark) rests at opacity 0.
- `test/core/widgets/state_issue_art_test.dart` checks both.

## Add or change a plate

1. Draw or edit `src/<plate>.svg`; `node tool/issue_art/build.js --sheet sheet.png` and look.
2. Add the new files' constants to `HeroAssets` (Issue states section).
3. Write the parts' tracks in `StateArtMotions`; a new issue also gets a `StateIssue` value
   (art, title and words keys in `assets/i18n/{en,ar}.json` under `issue`).
4. `flutter test test/core/design/hero_assets_svg_test.dart test/core/widgets/state_issue_art_test.dart`.
