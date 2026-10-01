# Hero icons

Source of the `HeroIcons` icon font (`assets/fonts/hero_icons.ttf`) and its generated Dart
constants (`lib/src/core/design/hero_icons.dart`).

```
npm ci                         # once (node_modules/ is git-ignored)
node build.js                  # src/*.svg → assets/fonts/hero_icons.ttf
node build.js --dart           # … + lib/src/core/design/hero_icons.dart
node build.js --qa .build/qa   # … + glyph vs source pixel diff, board.png, compare.png, qa.json
node build.js --out x.ttf      # write the font somewhere else (pilots, experiments)
```

Pipeline: strokes → fills (`oslllo-svg-fixer`, into `.build/fixed`) → SVG font
(`svgicons2svgfont`, `normalize: false`, `fontHeight: 1024`, `descent: 0`, so the 24 grid
fills the em box) → TTF (`svg2ttf`, fixed timestamp, so the same sources give the same bytes).
QA renders each glyph from the TTF (`opentype.js` + `resvg`) next to its source at 48 and
24 px and fails when more than 2 % of the pixels differ.

## Add an icon

1. Add a row to `concepts.tsv`: `name`, `dir` (`y` = flips in RTL), a one-line drawing note
   (it becomes the Dart doc comment), the names it replaces, and `fill` (only with an accent layer,
   see below).
2. `node build.js --sync` appends the name to `codepoints.json` and rewrites `directional.json`.
3. Draw `src/<name>.svg` by the grammar below.
4. `node build.js --dart --qa .build/qa`, look at `.build/qa/board.png`, commit the source,
   `codepoints.json`, the TTF and the Dart file together.

Another name for an existing glyph (e.g. `account` → `person`, `deliveryDirectional` →
`delivery` with `dir=y`) goes in `aliases.json` instead: no source file, no glyph, just a Dart
constant with the target's codepoint (`matchTextDirection` from the alias's own `dir`).

`HeroIcons.accentOf(icon)` (generated) returns the `<name>Accent` layer of a two-tone icon, or
`null`. Its switch sits in a top-level function outside the `@staticIconProvider` class on
purpose: the icon tree shaker ignores constants inside that class, so accents referenced only
there would be cut from the release font.

Two-tone content icons also get `src/<name>.accent.svg`: ONE filled shape (`fill="#111827"`, no
stroke) whose edge runs on the centre line of the surrounding strokes, so it tucks under the line.
`--sync` appends its glyph `<name>Accent`; QA fails if any accent pixel falls outside the line
icon's filled silhouette. In the app (`HeroIcon`) it is drawn under the line glyph: in the icon's
natural fill under the dark-green ink by default, or in a `HeroIconTone`'s pair.

Every icon with an accent names its natural fill in the `fill` column of `concepts.tsv` (and no
other icon does; the build fails otherwise): `green` · `mint` · `amber` · `yellow` · `orange` ·
`red` · `sky` · `violet` · `cream`, after the sticker art in `assets/svg` (the brand's objects
saturated, containers pale). `--dart` emits `enum HeroIconFill` and `HeroIcons.fillOf(icon)`,
non-null exactly where `accentOf` is; the app maps each value to an `AppColors` token
(`core/design/hero_icon_fill_colors.dart`), so the generated file stays theme-free.

## Grammar (v1)

- Root: `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24"
  fill="none" stroke="#111827" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">`.
- Strokes only, width 2, round caps and joins; coordinates ≤ 1 decimal.
- Stroke centre lines inside x, y ∈ [3, 21] (2 px padding); circle icons ≈ Ø18, square ≈ 16×16.
- Soft corners (rounded rect r 2.5–3), no sharp mitres; counters and gaps ≥ 2 px.
- `*Fill` variants: `fill="#111827" stroke="none"`, the line icon's outer silhouette, details
  knocked out (`fill-rule="evenodd"` or a cut path).
- `bag`, `cart`, `basket`, `store`, `delivery` share the Hero bag: a rounded trapezoid wider at
  the bottom with one arched handle. No cape, no letter.
- Directional icons (`dir=y`) point to the end side (right in LTR); `back`, `chevronStart`,
  `arrowUpStart` point to the start. The constant sets `matchTextDirection: true`; never draw a
  mirrored copy.
- Original drawings only (never trace Material, Lucide, Phosphor, other apps' icons). No text.
- ≤ 700 B per file (the build fails above it).

## Codepoints are stable

`codepoints.json` maps every name to its codepoint, from `0xE000` up in `concepts.tsv` order.
Never renumber, reorder or reuse one: a new name appends at the next free codepoint, a dropped
icon keeps its slot. Code and cached fonts depend on these numbers.
