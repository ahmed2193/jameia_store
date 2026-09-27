#!/usr/bin/env node
// =============================================================================
// build_brand_glyphs.js — turns the letters of the Hero brand into Dart `Path`
// data, so the app draws its logo as vectors (no font shipped, every letter
// animates on its own):
//
//   * the "h" on the bag of the mark (Fredoka Bold), in the mark's 100-unit
//     design square;
//   * the wordmark "hero" (Fredoka Bold), one path per letter;
//   * the Arabic wordmark "هيرو" (Baloo Bhaijaan 2 ExtraBold), one path per
//     joined run of letters (opentype.js does the Arabic shaping).
//
//   cd tool/splash
//   npm i --no-save opentype.js@1.3.4
//   curl -L -o fredoka-700.ttf \
//     https://cdn.jsdelivr.net/fontsource/fonts/fredoka@latest/latin-700-normal.ttf
//   curl -L -o baloo-bhaijaan-2-800.ttf \
//     https://cdn.jsdelivr.net/fontsource/fonts/baloo-bhaijaan-2@latest/arabic-800-normal.ttf
//   node build_brand_glyphs.js fredoka-700.ttf baloo-bhaijaan-2-800.ttf
//
// Writes lib/src/core/design/hero_glyphs.dart. Both fonts are SIL Open Font
// License 1.1.
// =============================================================================
'use strict';

const fs = require('fs');
const path = require('path');
const opentype = require('opentype.js');

const [latinPath, arabicPath] = process.argv.slice(2);
if (!latinPath || !arabicPath) {
  console.error('usage: node build_brand_glyphs.js <fredoka-700.ttf> <baloo-bhaijaan-2-800.ttf>');
  process.exit(1);
}

const LATIN = 'hero';
const ARABIC = 'هيرو';

/** Tighter than the fonts' own spacing, like the logo (font units). */
const LATIN_TRACKING = -10;
const ARABIC_TRACKING = 0;

/** Where the emblem "h" sits on the bag: centre and ink height, design units. */
const EMBLEM_CENTER = [58, 65];
const EMBLEM_HEIGHT = 30;

/** Arabic letters that never join the letter after them (end a joined run). */
const RIGHT_JOINING = new Set([...'اأإآدذرزوؤة']);

const OUT = path.join(__dirname, '..', '..', 'lib/src/core/design/hero_glyphs.dart');

const latinFont = opentype.loadSync(latinPath);
const arabicFont = opentype.loadSync(arabicPath);

const num = (v, digits = 1) => {
  const f = 10 ** digits;
  const n = Math.round(v * f) / f;
  return Number.isInteger(n) ? `${n}.0` : `${n}`;
};

/**
 * Dart cascade lines for opentype path commands mapped through
 * (x, y) → [sx * x + dx, -sy * y + dy] (y flipped: font y-up → Dart y-down).
 */
function cascade(commands, { sx = 1, dx = 0, dy = 0, digits = 1 } = {}) {
  const X = (x) => num(sx * x + dx, digits);
  const Y = (y) => num(-sx * y + dy, digits);
  return commands.map((c) => {
    switch (c.type) {
      case 'M':
        return `..moveTo(${X(c.x)}, ${Y(c.y)})`;
      case 'L':
        return `..lineTo(${X(c.x)}, ${Y(c.y)})`;
      case 'Q':
        return `..quadraticBezierTo(${X(c.x1)}, ${Y(c.y1)}, ${X(c.x)}, ${Y(c.y)})`;
      case 'C':
        return `..cubicTo(${X(c.x1)}, ${Y(c.y1)}, ${X(c.x2)}, ${Y(c.y2)}, ${X(c.x)}, ${Y(c.y)})`;
      case 'Z':
        return '..close()';
      default:
        throw new Error(`unknown path command ${c.type}`);
    }
  });
}

/** Glyphs of [text] with their pen x (font units, visual order). */
function layout(font, text, tracking) {
  const placed = [];
  font.forEachGlyph(text, 0, 0, font.unitsPerEm, { kerning: true, features: { liga: false } }, (glyph, x) => {
    placed.push({ glyph, x });
  });
  // Tracking: every glyph after the first moves by `tracking` per step.
  return placed.map((p, i) => ({ glyph: p.glyph, x: p.x + i * tracking }));
}

/** Ink bounds (font units, y down) of glyphs placed at their pens. */
function inkOf(placed) {
  let x1 = Infinity, y1 = Infinity, x2 = -Infinity, y2 = -Infinity;
  for (const { glyph, x } of placed) {
    const b = glyph.getBoundingBox();
    if (b.x1 === b.x2) continue;
    x1 = Math.min(x1, x + b.x1);
    x2 = Math.max(x2, x + b.x2);
    y1 = Math.min(y1, -b.y2);
    y2 = Math.max(y2, -b.y1);
  }
  return { x1, y1, x2, y2 };
}

function pathField(lines, indent = '    ') {
  return lines.map((l, i) => `${indent}${l}${i === lines.length - 1 ? '' : ''}`).join('\n');
}

// ── Emblem: the "h" fitted onto the bag ─────────────────────────────────────
const h = latinFont.charToGlyph('h');
const hb = h.getBoundingBox();
const hs = EMBLEM_HEIGHT / (hb.y2 - hb.y1);
const emblem = cascade(h.path.commands, {
  sx: hs,
  dx: EMBLEM_CENTER[0] - ((hb.x1 + hb.x2) / 2) * hs,
  dy: EMBLEM_CENTER[1] + ((hb.y1 + hb.y2) / 2) * hs,
  digits: 2,
});

// ── Latin wordmark: one path per letter ─────────────────────────────────────
const latin = layout(latinFont, LATIN, LATIN_TRACKING);
const latinInk = inkOf(latin);

// ── Arabic wordmark: one path per joined run, in reading order ─────────────
const arabic = layout(arabicFont, ARABIC, ARABIC_TRACKING);
const arabicInk = inkOf(arabic);
// forEachGlyph lays the word out left to right (visual order); reading order
// is right to left. A run ends after a letter that does not join onward.
const letters = [...ARABIC];
const readingGlyphs = arabic.slice().reverse();
if (readingGlyphs.length !== letters.length) {
  throw new Error(`expected one glyph per Arabic letter, got ${readingGlyphs.length}`);
}
const runs = [];
let run = [];
readingGlyphs.forEach((g, i) => {
  run.push(g);
  if (RIGHT_JOINING.has(letters[i]) || i === letters.length - 1) {
    runs.push(run);
    run = [];
  }
});

// ── Dart ────────────────────────────────────────────────────────────────────
const rect = (b) => `Rect.fromLTRB(${num(b.x1)}, ${num(b.y1)}, ${num(b.x2)}, ${num(b.y2)})`;
let out = '';
out += '// GENERATED by tool/splash/build_brand_glyphs.js — do not edit by hand.\n';
out += '// Outlines: Fredoka Bold (© The Fredoka Project Authors) and Baloo Bhaijaan 2\n';
out += '// ExtraBold (© Ek Type), both SIL Open Font License 1.1.\n';
out += "import 'dart:ui';\n\n";
out += '/// The letters of the Hero brand as vector outlines: the "h" on the bag of\n';
out += '/// the mark and the two wordmarks, "hero" and "هيرو". The wordmarks are in\n';
out += '/// font units ([unitsPerEm] per em, y down, baseline at 0) with every path\n';
out += '/// already at its place along the line.\n';
out += 'abstract final class HeroGlyphs {\n';
out += `  static const double unitsPerEm = ${num(latinFont.unitsPerEm)};\n\n`;
out += '  /// The emblem "h", in the mark\'s 100-unit design square.\n';
out += `  static final Path emblem = Path()\n${pathField(emblem)};\n\n`;
out += `  /// "${LATIN}", one path per letter in reading order.\n`;
out += '  static final List<Path> latin = <Path>[\n';
for (const { glyph, x } of latin) {
  out += `    Path()\n${pathField(cascade(glyph.path.commands, { dx: x }), '      ')},\n`;
}
out += '  ];\n\n';
out += '  /// Ink bounds of [latin].\n';
out += `  static const Rect latinInk = ${rect(latinInk)};\n\n`;
out += `  /// "${ARABIC}", one path per joined run of letters in reading order (right\n`;
out += '  /// to left).\n';
out += '  static final List<Path> arabic = <Path>[\n';
for (const r of runs) {
  const lines = [];
  for (const { glyph, x } of r) lines.push(...cascade(glyph.path.commands, { dx: x }));
  out += `    Path()\n${pathField(lines, '      ')},\n`;
}
out += '  ];\n\n';
out += '  /// Ink bounds of [arabic].\n';
out += `  static const Rect arabicInk = ${rect(arabicInk)};\n`;
out += '}\n';

fs.writeFileSync(OUT, out);
console.log(
  `wrote ${path.relative(process.cwd(), OUT)} — latin ink ${rect(latinInk)}, ` +
    `arabic ink ${rect(arabicInk)}, arabic runs ${runs.map((r) => r.length).join('+')}`,
);
