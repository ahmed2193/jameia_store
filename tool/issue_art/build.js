// Builds the layered state illustrations (assets/svg/state_*.svg) from
// tool/issue_art/src/*.svg — see README.md.
//
//   node tool/issue_art/build.js            masters → base + part SVGs in assets/svg/
//   node tool/issue_art/build.js --check    checks only, writes nothing
//   node tool/issue_art/build.js --sheet <out.png> [--bg #F8FAFC]
//                                           … + a contact sheet of every master at rest
//
// A master is one 160 × 120 sticker. Its top-level `<g id="part-NAME">` groups
// are the parts that move; everything else is the still base. The base keeps
// the master's file name; each part becomes `<master>_<name>.svg` (`-` → `_`)
// in the same frame, so the layers stack exactly. Parts sit over the base, in
// source order: no still element may follow the first part.
'use strict';

const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..', '..');
const srcDir = path.join(__dirname, 'src');
const outDir = path.join(root, 'assets', 'svg');
const colorsFile = path.join(root, 'lib', 'src', 'config', 'theme', 'app_colors.dart');
const manifestFile = path.join(root, 'docs', 'motion', 'asset_manifest.md');

const args = process.argv.slice(2);
const checkOnly = args.includes('--check');
const sheetAt = args.indexOf('--sheet');
const sheetOut = sheetAt >= 0 ? args[sheetAt + 1] : null;
const bgAt = args.indexOf('--bg');
const sheetBg = bgAt >= 0 ? args[bgAt + 1] : '#FFFFFF';

const MAX_BYTES = 10 * 1024;
const FORBIDDEN_TAGS = /<(text|image|style|filter|linearGradient|radialGradient|metadata|script|use|mask|pattern)\b/i;

/**
 * The art palette: the hexes of docs/motion/asset_manifest.md §1.3 ("Allowed
 * palette"), each of which must still be an AppColors colour.
 */
function palette() {
  const appColors = new Set();
  for (const match of fs.readFileSync(colorsFile, 'utf8').matchAll(/0x([0-9A-Fa-f]{8})/g)) {
    const argb = match[1].toUpperCase();
    if (argb.startsWith('FF')) appColors.add('#' + argb.slice(2));
  }
  const manifest = fs.readFileSync(manifestFile, 'utf8');
  const start = manifest.indexOf('### 1.3 Allowed palette');
  const end = manifest.indexOf('\n### ', start + 1);
  if (start < 0) throw new Error('asset_manifest.md has no "### 1.3 Allowed palette"');
  const hexes = new Set();
  for (const match of manifest.slice(start, end).matchAll(/^\|[^|]*\| `(#[0-9A-Fa-f]{6})` \|/gm)) {
    const hex = match[1].toUpperCase();
    if (!appColors.has(hex)) throw new Error(`palette ${hex} is not an AppColors colour`);
    hexes.add(hex);
  }
  return hexes;
}

/** Top-level elements of the svg root: `{ text, part }` in source order. */
function topLevel(svg, file) {
  const open = svg.match(/<svg\b[^>]*>/);
  const close = svg.lastIndexOf('</svg>');
  if (!open || close < 0) throw new Error(`${file}: no <svg> root`);
  const head = open[0];
  const body = svg.slice(open.index + head.length, close);
  const elements = [];
  const tag = /<!--[\s\S]*?-->|<\/?([a-zA-Z][\w-]*)\b[^>]*?(\/?)>/g;
  let depth = 0;
  let start = -1;
  let match;
  while ((match = tag.exec(body))) {
    const text = match[0];
    if (text.startsWith('<!--')) continue;
    const closing = text.startsWith('</');
    const selfClosing = match[2] === '/';
    if (!closing && depth === 0) start = match.index;
    if (closing) depth--;
    else if (!selfClosing) depth++;
    if (depth < 0) throw new Error(`${file}: unbalanced </${match[1]}>`);
    if (depth === 0 && start >= 0) {
      const element = body.slice(start, match.index + text.length);
      const id = element.match(/^<g\b[^>]*\bid="part-([a-z0-9-]+)"/);
      elements.push({ text: element, part: id ? id[1] : null });
      start = -1;
    }
  }
  if (depth !== 0) throw new Error(`${file}: unclosed element`);
  return { head, elements };
}

function check(name, svg, colors) {
  const problems = [];
  if (!/viewBox="0 0 160 120"/.test(svg) || !/width="160"/.test(svg) || !/height="120"/.test(svg)) {
    problems.push('frame must be width="160" height="120" viewBox="0 0 160 120"');
  }
  const forbidden = svg.match(FORBIDDEN_TAGS);
  if (forbidden) problems.push(`forbidden <${forbidden[1]}>`);
  for (const match of svg.matchAll(/#[0-9A-Fa-f]{6}\b/g)) {
    if (!colors.has(match[0].toUpperCase())) problems.push(`${match[0]} is not in the art palette (asset_manifest.md §1.3)`);
  }
  // Coordinates carry one decimal at most; opacities are not coordinates.
  const geometry = svg.replace(/\b(?:fill-|stroke-)?opacity="[^"]*"/g, '');
  for (const match of geometry.matchAll(/-?\d+\.\d{2,}/g)) {
    problems.push(`${match[0]}: one decimal at most`);
  }
  if (/\bid="/.test(svg)) problems.push('an id survived the split');
  const bytes = Buffer.byteLength(svg);
  if (bytes > MAX_BYTES) problems.push(`${bytes} B > ${MAX_BYTES} B`);
  return problems.map((problem) => `${name}: ${problem}`);
}

function wrap(head, inner) {
  return `${head}\n${inner}\n</svg>\n`;
}

function build() {
  const colors = palette();
  const masters = fs
    .readdirSync(srcDir)
    .filter((file) => file.endsWith('.svg'))
    .sort();
  const outputs = new Map();
  const problems = [];
  for (const file of masters) {
    const name = path.basename(file, '.svg');
    const svg = fs.readFileSync(path.join(srcDir, file), 'utf8').replace(/\r\n/g, '\n');
    const { head, elements } = topLevel(svg, file);
    const firstPart = elements.findIndex((element) => element.part);
    const base = [];
    const parts = [];
    elements.forEach((element, index) => {
      if (element.part) {
        const inner = element.text.replace(/\s*\bid="part-[a-z0-9-]+"/, '');
        parts.push({ file: `${name}_${element.part.replace(/-/g, '_')}.svg`, svg: wrap(head, `  ${inner}`) });
      } else {
        if (firstPart >= 0 && index > firstPart) {
          problems.push(`${file}: still element after the first part (parts draw over the base)`);
        }
        base.push(`  ${element.text}`);
      }
    });
    outputs.set(`${name}.svg`, wrap(head, base.join('\n')));
    for (const part of parts) outputs.set(part.file, part.svg);
    console.log(`${file}: base + ${parts.length} part(s)${parts.length ? ' — ' + parts.map((part) => part.file).join(', ') : ''}`);
  }
  for (const [file, svg] of outputs) problems.push(...check(file, svg, colors));
  if (problems.length) {
    console.error(problems.join('\n'));
    process.exit(1);
  }
  if (!checkOnly) {
    for (const [file, svg] of outputs) fs.writeFileSync(path.join(outDir, file), svg);
    console.log(`wrote ${outputs.size} files to assets/svg/`);
  }
  if (sheetOut) sheet(masters.map((file) => path.join(srcDir, file)), sheetOut);
}

/** Every master at rest (base + parts), 4 to a row, at 2×. */
function sheet(files, out) {
  const { Resvg } = require(path.join(root, 'tool', 'icons', 'node_modules', '@resvg', 'resvg-js'));
  const cols = Math.min(files.length, 4);
  const cellW = 160;
  const cellH = 140;
  const rows = Math.ceil(files.length / cols);
  let body = '';
  files.forEach((file, index) => {
    const svg = fs.readFileSync(file, 'utf8');
    const inner = svg.replace(/^[\s\S]*?<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '');
    const x = (index % cols) * cellW;
    const y = Math.floor(index / cols) * cellH;
    body +=
      `<g transform="translate(${x} ${y})"><svg width="160" height="120" viewBox="0 0 160 120">${inner}</svg>` +
      `<text x="80" y="134" font-size="9" text-anchor="middle" fill="#666666" font-family="Arial">${path.basename(file, '.svg')}</text></g>`;
  });
  const composed =
    `<svg xmlns="http://www.w3.org/2000/svg" width="${cols * cellW}" height="${rows * cellH}">` +
    `<rect width="100%" height="100%" fill="${sheetBg}"/>${body}</svg>`;
  const png = new Resvg(composed, { fitTo: { mode: 'zoom', value: 2 }, font: { loadSystemFonts: true } })
    .render()
    .asPng();
  fs.writeFileSync(out, png);
  console.log(`sheet: ${out}`);
}

build();
