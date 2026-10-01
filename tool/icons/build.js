#!/usr/bin/env node
// Builds the HeroIcons font from tool/icons/src/*.svg. See README.md.
//
//   node build.js                 → assets/fonts/hero_icons.ttf
//   node build.js --out <ttf>     → write the font somewhere else
//   node build.js --dart          → also lib/src/core/design/hero_icons.dart
//   node build.js --qa <dir>      → also render + pixel-diff every glyph, board.png
//   node build.js --sync          → append new concepts.tsv names to codepoints.json,
//                                   rewrite directional.json (run after adding a row)
//
// aliases.json maps an extra constant name to a drawn icon ("account": "person"): the alias gets
// the target's codepoint, no source file and no glyph; matchTextDirection follows its own dir flag.
import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(HERE, '..', '..');
const SRC = path.join(HERE, 'src');
const FIXED = path.join(HERE, '.build', 'fixed');
const FAMILY = 'HeroIcons';
const EM = 1024; // font units per em; the 24 grid is scaled up by EM / 24
const GRID = 24;
const MAX_BYTES = 700;
const ACCENT_EXT = '.accent.svg'; // src/<name>.accent.svg → glyph <name>Accent
const DIFF_LIMIT = 2; // % of pixels that may differ between a source and its glyph
const DIFF_ALPHA = 32; // a pixel differs when its coverage moves by more than 1/8
const OVERFLOW_ALPHA = 8; // accent coverage that counts as ink when checking overflow (1/32)
const SUPERSAMPLE = 8; // QA coverage = box filter over an 8× render
const INK = '#111827';
const BUILD_TS = 1790726400; // fixed font timestamp (2026-09-30) → reproducible bytes
// concepts.tsv `fill`: the natural colour of a two-tone icon's accent layer (HeroIconFill). The app
// maps each name to an AppColors token; the generated Dart stays theme-free.
const FILLS = {
  green: 'Brand green, saturated: the brand\'s own objects (bag, cart, store, delivery, pin, leaf).',
  mint: 'Pale brand mint: soft containers (chat, orders, clock face, person).',
  amber: 'Gold: value and rewards (star, points, wallet, crown, voucher).',
  yellow: 'Sunny yellow: light and attention (bell, lightbulb, sun, bolt).',
  orange: 'Warm orange: treats and heat (gift, tag, flame).',
  red: 'Offer red: love and deals (heart, discount), stop and cancel.',
  sky: 'Pale sky blue: information, tools and glass (search lens, mail, info, lock).',
  violet: 'Pale violet: Pro and magic (sparkle).',
  cream: 'Warm cream: paper, pantry and utensils (egg, coffee, edit, copy).',
};

const argv = process.argv.slice(2);
const has = (flag) => argv.includes(flag);
const valueOf = (flag) => {
  const i = argv.indexOf(flag);
  if (i < 0) return undefined;
  const v = argv[i + 1];
  if (!v || v.startsWith('--')) fail(`${flag} needs a value`);
  return path.resolve(v);
};
const out = valueOf('--out') ?? path.join(REPO, 'assets', 'fonts', 'hero_icons.ttf');
const qaDir = valueOf('--qa');

function fail(message) {
  console.error(`✗ ${message}`);
  process.exit(1);
}
const readJson = (file) => JSON.parse(fs.readFileSync(path.join(HERE, file), 'utf8'));
const writeJson = (file, data) => fs.writeFileSync(path.join(HERE, file), `${JSON.stringify(data, null, 2)}\n`);
const hex = (cp) => `0x${cp.toString(16).toUpperCase()}`;

/** concepts.tsv rows: name, dir (y/n), draw note, replaced names, accent fill. */
function readConcepts() {
  const [, ...rows] = fs.readFileSync(path.join(HERE, 'concepts.tsv'), 'utf8').split(/\r?\n/);
  return rows.filter((r) => r.trim()).map((r) => {
    const [name, dir, draw = '', , fill = ''] = r.split('\t');
    return { name, dir: dir === 'y', draw: draw.trim(), fill: fill.trim() || undefined };
  });
}

/** Every accent layer names a known fill, and only an icon with an accent names one. */
function checkFills(icons, concepts) {
  const accents = new Set(icons.filter((i) => i.accentOf).map((i) => i.accentOf));
  const errors = [];
  for (const c of concepts) {
    if (c.fill && !(c.fill in FILLS)) errors.push(`${c.name}: fill "${c.fill}" is not one of ${Object.keys(FILLS).join(', ')}`);
    if (c.fill && !accents.has(c.name)) errors.push(`${c.name}: fill without src/${c.name}${ACCENT_EXT}`);
    if (!c.fill && accents.has(c.name)) errors.push(`${c.name}: an accent layer needs a concepts.tsv fill`);
  }
  if (errors.length) fail(`fill check failed:\n  ${errors.join('\n  ')}`);
}

/** Codepoints never move: a new name gets max + 1, a dropped name keeps its slot. */
function sync(concepts) {
  const codepoints = readJson('codepoints.json');
  let next = Math.max(0xe000 - 1, ...Object.values(codepoints).map(Number)) + 1;
  const added = concepts.filter((c) => !(c.name in codepoints)).map((c) => c.name);
  // accent layers (src/<name>.accent.svg → <name>Accent), in concept order of their base icon
  const accents = new Set(fs.readdirSync(SRC).filter((f) => f.endsWith(ACCENT_EXT)).map((f) => f.slice(0, -ACCENT_EXT.length)));
  for (const c of concepts) if (accents.has(c.name) && !(`${c.name}Accent` in codepoints)) added.push(`${c.name}Accent`);
  for (const name of added) codepoints[name] = hex(next++);
  writeJson('codepoints.json', codepoints);
  writeJson('directional.json', concepts.filter((c) => c.dir).map((c) => c.name));
  console.log(`sync: ${added.length ? `added ${added.join(', ')}` : 'no new names'}`);
}

/** The source icons with their codepoints; stops on a missing codepoint or an oversize file. */
function readSources(codepoints) {
  const errors = [];
  const icons = fs.readdirSync(SRC).filter((f) => f.endsWith('.svg')).map((file) => {
    const accentOf = file.endsWith(ACCENT_EXT) ? file.slice(0, -ACCENT_EXT.length) : undefined;
    const name = accentOf ? `${accentOf}Accent` : file.slice(0, -4);
    const svg = fs.readFileSync(path.join(SRC, file), 'utf8');
    const bytes = Buffer.byteLength(svg);
    if (!(name in codepoints)) errors.push(`${name}: no codepoint (add a concepts.tsv row / the accent, run --sync)`);
    if (bytes > MAX_BYTES) errors.push(`${name}: ${bytes} B > ${MAX_BYTES} B`);
    if (!svg.includes(`viewBox="0 0 ${GRID} ${GRID}"`)) errors.push(`${name}: viewBox must be 0 0 ${GRID} ${GRID}`);
    if (accentOf && !fs.existsSync(path.join(SRC, `${accentOf}.svg`))) errors.push(`${name}: no src/${accentOf}.svg under it`);
    if (accentOf && /stroke="#/.test(svg)) errors.push(`${name}: an accent is one filled shape, no stroke`);
    return { name, file, svg, bytes, cp: Number(codepoints[name]), accentOf };
  });
  for (const [alias, target] of Object.entries(readAliases())) {
    if (icons.some((i) => i.name === alias)) errors.push(`${alias}: alias of ${target}, delete src/${alias}.svg`);
    if (!icons.some((i) => i.name === target)) errors.push(`${alias}: alias target ${target} has no source`);
  }
  if (errors.length) fail(`source check failed:\n  ${errors.join('\n  ')}`);
  if (!icons.length) fail('no icons in src/');
  return icons.sort((a, b) => a.cp - b.cp);
}

/** aliases.json: alias name → drawn icon name. */
function readAliases() {
  const file = path.join(HERE, 'aliases.json');
  return fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')) : {};
}

/** Strokes → filled outlines (oslllo-svg-fixer traces a raster of each source). */
async function fixStrokes() {
  const { default: SVGFixer } = await import('oslllo-svg-fixer');
  fs.rmSync(FIXED, { recursive: true, force: true });
  fs.mkdirSync(FIXED, { recursive: true });
  await SVGFixer(SRC, FIXED, { showProgressBar: false, throwIfDestinationDoesNotExist: false, traceResolution: 1200 }).fix();
}

/** Fixed outlines → SVG font (24 grid scaled to EM, baseline at the bottom) → TTF. */
async function buildTtf(icons) {
  const { SVGIcons2SVGFontStream } = await import('svgicons2svgfont');
  const { default: svg2ttf } = await import('svg2ttf');
  const svgFont = await new Promise((resolve, reject) => {
    const chunks = [];
    const stream = new SVGIcons2SVGFontStream({
      fontName: FAMILY, fontId: FAMILY, fontHeight: EM, descent: 0,
      normalize: false, centerHorizontally: false, log: () => {},
    });
    stream.on('data', (c) => chunks.push(c)).on('end', () => resolve(chunks.join(''))).on('error', reject);
    for (const icon of icons) {
      const glyph = fs.createReadStream(path.join(FIXED, icon.file));
      glyph.metadata = { name: icon.name, unicode: [String.fromCodePoint(icon.cp)] };
      stream.write(glyph);
    }
    stream.end();
  });
  const ttf = Buffer.from(svg2ttf(svgFont, {
    familyname: FAMILY, version: '1.0', ts: BUILD_TS,
    description: 'Hero icon font, generated by tool/icons/build.js', url: 'https://jm3eia.store',
  }).buffer);
  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, ttf);
  return ttf;
}

/** lib/src/core/design/hero_icons.dart: one const IconData per built icon. */
function writeDart(icons, concepts) {
  const directional = new Set(readJson('directional.json'));
  const notes = new Map(concepts.map((c) => [c.name, c.draw]));
  const sentence = (s) => (s ? `${s[0].toUpperCase()}${s.slice(1)}${/[.!?]$/.test(s) ? '' : '.'}` : 'Hero icon.');
  const body = icons.filter((i) => !i.accentOf).map(({ name, cp }) => {
    const dir = directional.has(name) ? ', matchTextDirection: true' : '';
    return `  /// ${sentence(notes.get(name))}\n  static const IconData ${name} = IconData(${hex(cp)}, fontFamily: fontFamily${dir});`;
  }).join('\n\n');
  // an accent shares its base glyph's direction, so the two layers stay aligned in RTL
  const accents = icons.filter((i) => i.accentOf).map(({ name, cp, accentOf }) => {
    const dir = directional.has(accentOf) ? ', matchTextDirection: true' : '';
    return `  /// Two-tone layer under [${accentOf}].\n  static const IconData ${name} = IconData(${hex(cp)}, fontFamily: fontFamily${dir});`;
  }).join('\n\n');
  const accentBlock = accents ? `\n  // Two-tone accent layers (src/<name>.accent.svg): drawn under the line glyph in a soft tone.\n\n${accents}\n` : '';
  const codepointOf = new Map(icons.map((i) => [i.name, i.cp]));
  const aliases = Object.entries(readAliases()).map(([alias, target]) => {
    const dir = directional.has(alias) ? ', matchTextDirection: true' : '';
    return `  /// The [${target}] glyph${dir ? ', flipped in RTL' : ''}.\n  static const IconData ${alias} = IconData(${hex(codepointOf.get(target))}, fontFamily: fontFamily${dir});`;
  }).join('\n\n');
  const aliasBlock = aliases ? `\n  // Aliases (tool/icons/aliases.json): another name for a drawn glyph.\n\n${aliases}\n` : '';
  // accentOf: base glyph codepoint → its accent layer. The switch lives in a top-level function
  // OUTSIDE the @staticIconProvider class: the icon tree shaker ignores every IconData constant
  // inside such a class, so accent glyphs referenced only there would be cut from the release font.
  const accentCases = icons.filter((i) => i.accentOf)
    .map(({ name, accentOf }) => `    ${hex(codepointOf.get(accentOf))} => HeroIcons.${name},`).join('\n');
  const accentOfMember = accentCases ? [
    '',
    '  /// The two-tone accent layer drawn under [icon], or `null` when [icon] has none or is not',
    '  /// a Hero glyph. Aliases resolve through their codepoint (`account` → `personAccent`).',
    '  static IconData? accentOf(IconData icon) => _accentOf(icon);',
    '',
    '  /// The natural colour of [icon]\'s accent layer (concepts.tsv `fill`); `null` exactly when',
    '  /// [accentOf] is `null`.',
    '  static HeroIconFill? fillOf(IconData icon) => _fillOf(icon);',
    '',
  ].join('\n') : '';
  const fillOfConcept = new Map(concepts.filter((c) => c.fill).map((c) => [c.name, c.fill]));
  const fillCases = icons.filter((i) => i.accentOf)
    .map(({ accentOf }) => `    ${hex(codepointOf.get(accentOf))} => HeroIconFill.${fillOfConcept.get(accentOf)},`).join('\n');
  const accentOfFunction = accentCases ? [
    '',
    '// Outside [HeroIcons] on purpose: the icon tree shaker skips the body of a @staticIconProvider',
    '// class, so the accent constants must be referenced from here to stay in the release font.',
    'IconData? _accentOf(IconData icon) {',
    '  if (icon.fontFamily != HeroIcons.fontFamily) return null;',
    '  final IconData? accent = switch (icon.codePoint) {',
    accentCases,
    '    _ => null,',
    '  };',
    '  // An alias with its own direction (deliveryDirectional) would leave its layer unflipped in RTL.',
    '  return accent?.matchTextDirection == icon.matchTextDirection ? accent : null;',
    '}',
    '',
    '// Guarded by [_accentOf], so a fill exists exactly where an accent layer is drawn.',
    'HeroIconFill? _fillOf(IconData icon) {',
    '  if (_accentOf(icon) == null) return null;',
    '  return switch (icon.codePoint) {',
    fillCases,
    '    _ => null,',
    '  };',
    '}',
    '',
    '/// The natural colour of a two-tone icon\'s accent layer ([HeroIcons.fillOf]), after the sticker',
    '/// art in `assets/svg`. The app maps each value to an `AppColors` token.',
    'enum HeroIconFill {',
    Object.entries(FILLS).map(([name, doc]) => `  /// ${doc}\n  ${name},`).join('\n\n'),
    '}',
    '',
  ].join('\n') : '';
  // byName: every constant by its source name, so tests can walk the whole font (IconData takes
  // const arguments only). Inside the class, so it keeps no glyph in the release font.
  const byNameEntries = [...icons.map((i) => i.name), ...Object.keys(readAliases())]
    .map((name) => `    '${name}': ${name},`).join('\n');
  const byNameMember = [
    '',
    '  /// Every constant above by its source name (glyphs, accent layers, aliases), for tests and',
    '  /// tooling that walk the whole font.',
    '  static const Map<String, IconData> byName = <String, IconData>{',
    byNameEntries,
    '  };',
    '',
  ].join('\n');
  const file = path.join(REPO, 'lib', 'src', 'core', 'design', 'hero_icons.dart');
  fs.writeFileSync(file, `// GENERATED by tool/icons/build.js — do not edit by hand.
// Sources: tool/icons/src/*.svg · codepoints: tool/icons/codepoints.json

import 'package:flutter/widgets.dart';

/// The Hero icon font (\`assets/fonts/hero_icons.ttf\`, family [fontFamily]).
///
/// Directional icons set \`matchTextDirection\`, so they flip in RTL.
@staticIconProvider
abstract final class HeroIcons {
  /// The font family declared in pubspec.yaml.
  static const String fontFamily = '${FAMILY}';

${body}
${accentBlock}${aliasBlock}${accentOfMember}${byNameMember}}
${accentOfFunction}`);
  const fmt = spawnSync('dart', ['format', file], { stdio: 'ignore', shell: process.platform === 'win32' });
  console.log(`dart: ${path.relative(REPO, file)} (${icons.length} icons + ${Object.keys(readAliases()).length} aliases${fmt.status === 0 ? ', formatted' : ''})`);
}

/**
 * Splits path data into subpaths that each start with an absolute M, so every subpath can be
 * filled on its own (one fill of the whole path lets opposite windings cancel into holes).
 */
function splitSubpaths(d) {
  const tokens = d.match(/[a-zA-Z]|-?(?:\d+\.?\d*|\.\d+)(?:e-?\d+)?/g) ?? [];
  const arity = { M: 2, L: 2, H: 1, V: 1, C: 6, S: 4, Q: 4, T: 2, A: 7, Z: 0 };
  const parts = [];
  let cur = [0, 0], start = [0, 0], out = '', cmd = '', i = 0;
  while (i < tokens.length) {
    if (/[a-zA-Z]/.test(tokens[i])) cmd = tokens[i++];
    const up = cmd.toUpperCase(), rel = cmd !== up;
    if (up === 'Z') { out += 'Z'; cur = [...start]; cmd = ''; continue; }
    const a = tokens.slice(i, i + arity[up]).map(Number); i += arity[up];
    if (up === 'M') {
      if (out) parts.push(out);
      cur = rel ? [cur[0] + a[0], cur[1] + a[1]] : a;
      start = [...cur];
      out = `M${cur[0]} ${cur[1]}`;
      cmd = rel ? 'l' : 'L'; // extra pairs after M/m are line-tos
      continue;
    }
    out += `${cmd}${a.join(' ')}`;
    if (up === 'H') cur = [rel ? cur[0] + a[0] : a[0], cur[1]];
    else if (up === 'V') cur = [cur[0], rel ? cur[1] + a[0] : a[0]];
    else { const [x, y] = a.slice(-2); cur = rel ? [cur[0] + x, cur[1] + y] : [x, y]; }
  }
  if (out) parts.push(out);
  return parts;
}

/** The line icon with every shape and every subpath filled: the area an accent may cover. */
function silhouetteSvg(svg) {
  return svg.replace('fill="none"', `fill="${INK}"`).replace(/<path([^>]*?) d="([^"]+)"([^>]*)\/>/g,
    (_, pre, d, post) => splitSubpaths(d).map((p) => `<path${pre} d="${p}"${post}/>`).join(''));
}

/** Renders every glyph from the TTF beside its source, pixel-diffs them, writes the boards. */
async function qa(icons, ttf) {
  const { Resvg } = await import('@resvg/resvg-js');
  const { default: opentype } = await import('opentype.js');
  const font = opentype.parse(ttf.buffer.slice(ttf.byteOffset, ttf.byteOffset + ttf.byteLength));
  const fontDir = path.join(REPO, 'assets', 'fonts');
  const text = fs.existsSync(fontDir)
    ? { fontDirs: [fontDir], loadSystemFonts: false, defaultFontFamily: 'Noto Sans' }
    : { loadSystemFonts: true };
  const render = (svg, width) => new Resvg(svg, { fitTo: { mode: 'width', value: width }, font: text }).render();
  const glyphPath = (cp, size) => font.charToGlyph(String.fromCodePoint(cp)).getPath(0, size, size).toPathData(2);
  const glyphSvg = (cp, size) => `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}"><path fill="${INK}" d="${glyphPath(cp, size)}"/></svg>`;
  // Coverage per pixel, box-filtered from a SUPERSAMPLE× render: resvg's direct small-size
  // stroke rasterizer is itself off by up to ~4 % of pixels at 24 px, the supersampled
  // coverage is exact, so source and glyph are measured the same way.
  const alpha = (svg, size) => {
    const w = size * SUPERSAMPLE;
    const px = render(svg, w).pixels;
    const cov = new Float64Array(size * size);
    for (let y = 0; y < w; y++) {
      for (let x = 0; x < w; x++) cov[Math.floor(y / SUPERSAMPLE) * size + Math.floor(x / SUPERSAMPLE)] += px[(y * w + x) * 4 + 3];
    }
    return cov.map((v) => v / SUPERSAMPLE ** 2);
  };
  const diff = (icon, size) => {
    const a = alpha(icon.svg, size);
    const b = alpha(glyphSvg(icon.cp, size), size);
    const cells = [];
    let error = 0;
    a.forEach((v, i) => {
      const d = Math.abs(v - b[i]);
      error += d;
      if (d > DIFF_ALPHA) cells.push(i);
    });
    // pct: pixels that differ; mae: mean coverage error over the cell (both in %).
    return { pct: (100 * cells.length) / (size * size), mae: (100 * error) / (255 * size * size), cells };
  };
  const results = icons.map((icon) => {
    const d48 = diff(icon, 48);
    const d24 = diff(icon, 24);
    const box = font.charToGlyph(String.fromCodePoint(icon.cp)).getBoundingBox();
    const u = GRID / EM; // font units → grid units (y up in the font)
    const bbox = [box.x1 * u, GRID - box.y2 * u, box.x2 * u, GRID - box.y1 * u].map((v) => Math.round(v * 10) / 10);
    const outside = bbox[0] < 1.9 || bbox[1] < 1.9 || bbox[2] > 22.1 || bbox[3] > 22.1;
    // an accent must stay inside its line icon's silhouette (the line icon with every shape filled)
    let overflow;
    if (icon.accentOf) {
      const base = silhouetteSvg(icons.find((i) => i.name === icon.accentOf).svg);
      const acc = alpha(icon.svg, 48), sil = alpha(base, 48);
      overflow = acc.reduce((n, v, i) => n + (v > OVERFLOW_ALPHA && sil[i] <= OVERFLOW_ALPHA ? 1 : 0), 0);
    }
    const flagged = d48.pct > DIFF_LIMIT || d24.pct > DIFF_LIMIT || overflow > 0;
    return { ...icon, d48, d24, bbox, outside, overflow, flagged };
  });
  fs.mkdirSync(qaDir, { recursive: true });

  // compare.png: source | glyph | diff cells, at 48 and 24.
  const nest = (svg, x, y, s) => svg.replace('<svg ', `<svg x="${x}" y="${y}" `).replace(/width="\d+" height="\d+"/, `width="${s}" height="${s}"`);
  const cells = (list, size, x, y, scale) => list.map((i) => `<rect x="${x + (i % size) * scale}" y="${y + Math.floor(i / size) * scale}" width="${scale}" height="${scale}" fill="#dc2626"/>`).join('');
  const rowH = 64;
  let cmp = '';
  results.forEach((r, k) => {
    const y = k * rowH + 8;
    cmp += `<text x="8" y="${y + 30}" font-size="12" fill="${r.flagged ? '#dc2626' : '#374151'}">${r.name}</text>`;
    cmp += `<text x="8" y="${y + 46}" font-size="10" fill="#6b7280">${r.d48.pct.toFixed(2)}% · ${r.d24.pct.toFixed(2)}%</text>`;
    cmp += nest(r.svg.trim(), 130, y, 48) + nest(glyphSvg(r.cp, 48), 186, y, 48);
    cmp += `<rect x="242" y="${y}" width="48" height="48" fill="#f3f4f6"/>${cells(r.d48.cells, 48, 242, y, 1)}`;
    cmp += nest(r.svg.trim(), 306, y + 12, 24) + nest(glyphSvg(r.cp, 24), 338, y + 12, 24);
    cmp += `<rect x="370" y="${y}" width="48" height="48" fill="#f3f4f6"/>${cells(r.d24.cells, 24, 370, y, 2)}`;
  });
  const cmpSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="430" height="${results.length * rowH + 8}" font-family="Noto Sans"><rect width="100%" height="100%" fill="#fff"/>${cmp}</svg>`;
  fs.writeFileSync(path.join(qaDir, 'compare.png'), render(cmpSvg, 860).asPng());

  // board.png: name, glyph at 48, 24 and 16 (true pixels); board@2x.png for review.
  const cols = 8, cw = 150, ch = 92;
  let board = '';
  results.forEach((r, k) => {
    const x = (k % cols) * cw, y = Math.floor(k / cols) * ch;
    board += `<rect x="${x + 4}" y="${y + 4}" width="${cw - 8}" height="${ch - 8}" rx="10" fill="#f9fafb" stroke="${r.flagged || r.outside ? '#dc2626' : '#e5e7eb'}"/>`;
    board += `<text x="${x + 12}" y="${y + 20}" font-size="11" fill="#374151">${r.name}</text>`;
    board += `<text x="${x + cw - 12}" y="${y + 20}" font-size="9" text-anchor="end" fill="#9ca3af">${hex(r.cp)}</text>`;
    board += nest(glyphSvg(r.cp, 48), x + 12, y + 30, 48) + nest(glyphSvg(r.cp, 24), x + 76, y + 42, 24) + nest(glyphSvg(r.cp, 16), x + 112, y + 46, 16);
  });
  const w = cols * cw, h = Math.ceil(results.length / cols) * ch;
  const boardSvg = `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" font-family="Noto Sans"><rect width="100%" height="100%" fill="#fff"/>${board}</svg>`;
  fs.writeFileSync(path.join(qaDir, 'board.png'), render(boardSvg, w).asPng());
  fs.writeFileSync(path.join(qaDir, 'board@2x.png'), render(boardSvg, w * 2).asPng());
  fs.writeFileSync(path.join(qaDir, 'qa.json'), `${JSON.stringify(results.map((r) => ({
    name: r.name, codepoint: hex(r.cp), bytes: r.bytes, diff48: +r.d48.pct.toFixed(2), diff24: +r.d24.pct.toFixed(2), mae48: +r.d48.mae.toFixed(2), bbox: r.bbox, flagged: r.flagged, outside: r.outside, ...(r.accentOf ? { overflow: r.overflow } : {}),
  })), null, 2)}\n`);

  for (const r of results) {
    const mark = r.flagged ? '✗' : r.outside ? '!' : ' ';
    console.log(`${mark} ${r.name.padEnd(20)} ${r.d48.pct.toFixed(2).padStart(5)}% @48  ${r.d24.pct.toFixed(2).padStart(5)}% @24  mae ${r.d48.mae.toFixed(2)}%  ${String(r.bytes).padStart(3)} B  bbox ${r.bbox.join(',')}${r.accentOf ? `  overflow ${r.overflow} px` : ''}`);
  }
  const worst = Math.max(...results.map((r) => Math.max(r.d48.pct, r.d24.pct)));
  const flagged = results.filter((r) => r.flagged).map((r) => r.name);
  const accents = results.filter((r) => r.accentOf);
  if (accents.length) console.log(`qa: ${accents.length} accents, overflow past the line silhouette: ${accents.reduce((n, r) => n + r.overflow, 0)} px`);
  console.log(`qa: max diff ${worst.toFixed(2)}% (limit ${DIFF_LIMIT}%) → ${path.relative(process.cwd(), qaDir) || qaDir}`);
  if (flagged.length) fail(`over the diff limit or accent overflow: ${flagged.join(', ')}`);
}

const concepts = readConcepts();
if (has('--sync')) sync(concepts);
const icons = readSources(readJson('codepoints.json'));
checkFills(icons, concepts);
await fixStrokes();
const ttf = await buildTtf(icons);
console.log(`font: ${icons.length} glyphs, ${ttf.length} B → ${out}`);
if (has('--dart')) writeDart(icons, concepts);
if (qaDir) await qa(icons, ttf);
