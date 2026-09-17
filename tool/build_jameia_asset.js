/**
 * build_jameia_asset.js — offline transform (run with Node, NOT bundled).
 *
 * Turns the heavy full-fidelity Jameia captures into ONE slim, SKU-keyed asset
 * the JameiaMart bundles + parses (in an isolate) at boot.
 *
 *   IN : <repo>/JAMEIA_CATEGORIES_DATA.json        (Mart, isVIP=false)
 *        <repo>/JAMEIA_CATEGORIES_DATA_VIP.json    (VIP, for the VIP price/SKU)
 *   OUT: jameia_mart/assets/data/jameia/jameia_catalog.json
 *
 * Why slim: the raw Mart file is ~51MB / 9,380 product ROWS but only ~8,352
 * UNIQUE SKUs (the same product is nested under many ranks). We:
 *   - dedup products into ONE dict keyed by sku (compact keys, defaults omitted),
 *   - reference products everywhere else by sku-list only,
 *   - merge the VIP price per-sku (VIP file's `price` == the VIP price),
 *   - strip the media domain (re-prepended by the Dart loader).
 * Result: a few MB instead of 50+, parseable off the main thread.
 *
 * Usage:  node jameia_mart/tool/build_jameia_asset.js
 *         (paths are resolved relative to the jm3eia_mobile repo root)
 */
'use strict';
const fs = require('fs');
const path = require('path');

const SRC_DIR = 'F:/_jam3eia_apps/jm3eia_mobile';
const OUT = path.join(__dirname, '..', 'assets', 'data', 'jameia', 'jameia_catalog.json');
const MEDIA = 'https://media.jm3eia.com';

const readJson = (p) =>
  JSON.parse(fs.readFileSync(p, 'utf8').replace(/^﻿/, ''));

const num = (v) => {
  if (v == null) return 0;
  if (typeof v === 'number') return v;
  const n = parseFloat(String(v));
  return Number.isFinite(n) ? n : 0;
};
const r3 = (n) => Math.round(n * 1000) / 1000; // keep 3dp (fils), drop float noise
const stripMedia = (u) => {
  if (typeof u !== 'string' || u.length === 0) return '';
  return u.startsWith(MEDIA) ? u.slice(MEDIA.length) : u;
};
const slidePics = (slides) => {
  if (!Array.isArray(slides)) return [];
  return slides
    .map((s) => stripMedia(typeof s === 'string' ? s : (s && (s.picture || s.image)) || ''))
    .filter(Boolean);
};

// ── 1. VIP price per sku (VIP file's `price` IS the VIP price) ────────────────
function buildVipMap() {
  const vip = new Map();
  let vjson;
  try {
    vjson = readJson(path.join(SRC_DIR, 'JAMEIA_CATEGORIES_DATA_VIP.json'));
  } catch (e) {
    console.warn('! VIP file missing/unreadable — VIP prices skipped:', e.message);
    return vip;
  }
  const eat = (p) => { if (p && p.sku != null) vip.set(String(p.sku), r3(num(p.price))); };
  for (const c of vjson.data || [])
    for (const s of c.subCategories || []) {
      for (const p of s.products || []) eat(p);
      for (const rk of s.ranks || []) for (const p of rk.products || []) eat(p);
    }
  for (const sec of vjson.sections || []) for (const p of sec.products || []) eat(p);
  return vip;
}

// ── 2. Mart catalog → slim asset ─────────────────────────────────────────────
function main() {
  const vipBySku = buildVipMap();
  const mart = readJson(path.join(SRC_DIR, 'JAMEIA_CATEGORIES_DATA.json'));

  const products = {}; // sku -> compact product (first occurrence wins)
  const addProduct = (p) => {
    if (!p || p.sku == null) return null;
    const sku = String(p.sku);
    if (!products[sku]) {
      const price = r3(num(p.price));
      const old = r3(num(p.old_price));
      const vip = vipBySku.has(sku) ? vipBySku.get(sku) : null;
      const o = { s: sku, n: p.name || '', a: p.name_ar || '', p: price, i: stripMedia(p.picture) };
      if (old > 0 && old !== price) o.o = old;                 // struck price
      if (vip != null && vip > 0 && vip !== price) o.v = vip;  // VIP price (only when it differs)
      if (p.availability === false) o.av = 0;                  // default available
      if (p.has_variants === true) o.hv = 1;                   // default no variants
      if (p.show_discount_percentage === true) o.d = 1;        // promo badge driver
      const mq = Math.round(num(p.max_quantity_cart));
      if (mq > 0) o.m = mq;
      const fq = Math.round(num(p.first_units_quantity));
      if (fq > 0) o.f = fq;
      products[sku] = o;
    }
    return sku;
  };
  const skusOf = (list) => {
    const out = [];
    for (const p of list || []) { const s = addProduct(p); if (s) out.push(s); }
    return out;
  };

  // taxonomy (categories -> subs metadata, from the `data` tree which carries
  // ranks+products; fall back to `taxonomy` for names/pictures of subs).
  const taxById = {};
  for (const t of mart.taxonomy || []) {
    taxById[t._id] = t;
    for (const ch of t.children || []) taxById[ch._id] = ch;
  }

  const categories = [];
  for (const c of mart.data || []) {
    const meta = taxById[c._id] || {};
    const subs = [];
    for (const s of c.subCategories || []) {
      const sMeta = taxById[s._id] || {};
      const ranks = [];
      for (const rk of s.ranks || []) {
        ranks.push({
          id: rk._id,
          name: rk.name || '',
          nameAr: rk.name_ar || '',
          img: stripMedia(rk.picture),
          count: Math.round(num(rk.count)) || (rk.products ? rk.products.length : 0),
          skus: skusOf(rk.products),
        });
      }
      const sub = {
        id: s._id,
        name: s.name || sMeta.name || '',
        nameAr: s.name_ar || sMeta.name_ar || '',
        img: stripMedia(s.picture || sMeta.picture),
        ranks,
      };
      const direct = skusOf(s.products);
      if (direct.length) sub.skus = direct;             // 0-rank subcategory
      const banner = stripMedia((s.banner && (s.banner.picture || s.banner)) || '');
      if (banner) sub.banner = banner;
      subs.push(sub);
    }
    categories.push({
      id: c._id,
      name: c.name || meta.name || '',
      nameAr: c.name_ar || meta.name_ar || '',
      img: stripMedia(meta.picture || c.picture),
      subs,
    });
  }

  // featured menu sections (the home rails).
  const sections = [];
  for (const sec of mart.sections || []) {
    sections.push({
      id: sec._id,
      name: sec.name || '',
      nameAr: sec.name_ar || '',
      sort: num(sec.sorting),
      slides: slidePics(sec.slides),
      skus: skusOf(sec.products),
    });
  }
  sections.sort((a, b) => a.sort - b.sort);

  // settings (VIP/Mart card + display flags).
  const st = mart.settings || {};
  const content = (st.display && st.display.content) || {};
  const card = (k) => {
    const c = content[k] || {};
    const pick = (o) => (o && (o.en || o.ar)) || '';
    return {
      titleEn: (c.title && c.title.en) || '',
      titleAr: (c.title && c.title.ar) || '',
      descEn: (c.description && c.description.en) || '',
      descAr: (c.description && c.description.ar) || '',
      img: stripMedia(pick(c.picture)),
    };
  };
  const settings = {
    prepTime: Math.round(num(st.preparation_time)) || 0,
    displayOrderAgain: !!(st.display && st.display.display_order_again),
    displayBestSelling: !!(st.display && st.display.display_best_selling),
    vip: card('jm3eia_vip'),
    mart: card('jm3eia_mart'),
  };

  const asset = {
    meta: {
      mediaBase: MEDIA,
      built: mart.meta && mart.meta.date,
      totals: {
        categories: categories.length,
        subCategories: categories.reduce((n, c) => n + c.subs.length, 0),
        sections: sections.length,
        products: Object.keys(products).length,
      },
    },
    settings,
    categories,
    sections,
    products,
  };

  fs.mkdirSync(path.dirname(OUT), { recursive: true });
  fs.writeFileSync(OUT, JSON.stringify(asset));
  const mb = (fs.statSync(OUT).size / 1048576).toFixed(2);
  console.log('WROTE', OUT, mb + 'MB');
  console.log('totals', JSON.stringify(asset.meta.totals));
  const withVip = Object.values(products).filter((p) => p.v != null).length;
  console.log('products with VIP price:', withVip, '/', Object.keys(products).length);
}

main();
