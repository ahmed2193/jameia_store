#!/usr/bin/env node
// Checks every PUBLIC catalogue / bootstrap GET of the jm3eia API against the live OpenAPI spec:
// calls each route (en + ar, every slug the lists return, every product filter / sort, the
// 404 / 400 paths) and validates the whole envelope with the 200 schema from /docs/json.
// Reports: spec violations (missing required, wrong type, bad enum, null where not nullable),
// fields the spec does not declare, and the row counts of each product filter.
//
// Read-only, sequential, throttled (~250 requests; the host allows 300 / 60 s), honours 429.
// Node >= 18.   node .claude/skills/jameia-api-verify/scripts/validate_live_catalog.js
//   API_BASE_URL=http://localhost:5056   another host (e.g. the mock)
//   OPENAPI_FILE=<saved /docs/json>      validate against a saved spec
//   REPORT_FILE=<path.json>              also write the full per-request report
// Exit code 1 when any reply violates the spec.
const fs = require('fs');
const BASE = (process.env.API_BASE_URL || 'https://api.jm3eia.store').replace(/\/$/, '');
let spec; // loaded in main()
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const deref = (s) => {
  while (s && s.$ref) {
    const name = s.$ref.split('/').pop();
    s = spec.components.schemas[name];
  }
  return s;
};

// Returns list of problems; `extras` collects fields the spec does not declare.
function validate(schema, value, path, out) {
  schema = deref(schema);
  if (!schema) return;
  if (value === null) {
    if (schema.nullable) return;
    const alts = schema.anyOf || schema.oneOf;
    if (alts && alts.some((a) => { a = deref(a); return a.nullable || a.type === 'null' || (a.enum && a.enum.includes(null)); })) return;
    if (schema.type === 'null' || (schema.enum && schema.enum.includes(null))) return;
    out.errors.push(`${path}: null not allowed by spec`);
    return;
  }
  const alts = schema.anyOf || schema.oneOf;
  if (alts) {
    let best = null;
    for (const a of alts) {
      const o = { errors: [], extras: [] };
      validate(a, value, path, o);
      if (!best || o.errors.length < best.errors.length) best = o;
      if (o.errors.length === 0) break;
    }
    out.errors.push(...best.errors);
    out.extras.push(...best.extras);
    return;
  }
  if (schema.allOf) { for (const a of schema.allOf) validate(a, value, path, out); return; }
  if (schema.enum && !schema.enum.includes(value)) out.errors.push(`${path}: "${value}" not in enum [${schema.enum.join(', ')}]`);
  const t = schema.type;
  const jsType = Array.isArray(value) ? 'array' : typeof value;
  if (t === 'object' || (!t && schema.properties)) {
    if (jsType !== 'object') { out.errors.push(`${path}: expected object, got ${jsType}`); return; }
    for (const r of schema.required || []) if (!(r in value)) out.errors.push(`${path}.${r}: required field missing`);
    const props = schema.properties || {};
    for (const k of Object.keys(value)) {
      if (props[k]) validate(props[k], value[k], `${path}.${k}`, out);
      else if (schema.additionalProperties && typeof schema.additionalProperties === 'object') validate(schema.additionalProperties, value[k], `${path}.${k}`, out);
      else if (schema.properties) out.extras.push(`${path}.${k}`);
    }
  } else if (t === 'array') {
    if (jsType !== 'array') { out.errors.push(`${path}: expected array, got ${jsType}`); return; }
    value.forEach((v, i) => validate(schema.items, v, `${path}[${i}]`, out));
  } else if (t === 'integer') {
    if (!Number.isInteger(value)) out.errors.push(`${path}: expected integer, got ${JSON.stringify(value)}`);
  } else if (t === 'number') {
    if (jsType !== 'number') out.errors.push(`${path}: expected number, got ${jsType}`);
  } else if (t === 'string') {
    if (jsType !== 'string') out.errors.push(`${path}: expected string, got ${jsType}`);
    else {
      if (schema.pattern && !new RegExp(schema.pattern).test(value)) out.errors.push(`${path}: "${value}" fails pattern ${schema.pattern}`);
      if (schema.minLength != null && value.length < schema.minLength) out.errors.push(`${path}: shorter than minLength ${schema.minLength}`);
      if (schema.maxLength != null && value.length > schema.maxLength) out.errors.push(`${path}: longer than maxLength ${schema.maxLength}`);
    }
  } else if (t === 'boolean') {
    if (jsType !== 'boolean') out.errors.push(`${path}: expected boolean, got ${jsType}`);
  }
  if ((t === 'integer' || t === 'number') && typeof value === 'number') {
    if (schema.minimum != null && value < schema.minimum) out.errors.push(`${path}: ${value} < minimum ${schema.minimum}`);
    if (schema.maximum != null && value > schema.maximum) out.errors.push(`${path}: ${value} > maximum ${schema.maximum}`);
  }
}

const report = [];
async function call(specPath, url, lang, expectStatus = 200) {
  let res, body, tries = 0;
  for (;;) {
    res = await fetch(BASE + url, { headers: { 'Accept-Language': lang } });
    if (res.status === 429 && tries++ < 4) { await sleep((Number(res.headers.get('retry-after')) || 5) * 1000); continue; }
    break;
  }
  const text = await res.text();
  try { body = JSON.parse(text); } catch { body = null; }
  const row = { url, lang, status: res.status, errors: [], extras: [] };
  if (res.status !== expectStatus) row.errors.push(`HTTP ${res.status}, expected ${expectStatus}`);
  if (!body) row.errors.push('non-JSON body');
  else if (expectStatus === 200) {
    const op = spec.paths[specPath] && spec.paths[specPath].get;
    const schema = op && op.responses['200'] && op.responses['200'].content['application/json'].schema;
    if (!schema) row.errors.push('no 200 schema in spec for ' + specPath);
    else validate(schema, body, '$', row);
  } else {
    for (const k of ['success', 'statusCode', 'statusMessage', 'results', 'error']) if (!(k in body)) row.errors.push(`envelope key ${k} missing`);
    row.code = body.statusMessage;
  }
  // collapse [n] indexes so one bad field is reported once
  row.errors = [...new Set(row.errors.map((e) => e.replace(/\[\d+\]/g, '[]')))];
  row.extras = [...new Set(row.extras.map((e) => e.replace(/\[\d+\]/g, '[]')))];
  report.push(row);
  await sleep(120);
  return body;
}

(async () => {
  spec = process.env.OPENAPI_FILE
    ? JSON.parse(fs.readFileSync(process.env.OPENAPI_FILE, 'utf8'))
    : await (await fetch(BASE + '/docs/json')).json();
  const slugs = { categories: [], brands: [], products: [], collections: [], recipes: [] };
  for (const lang of ['en', 'ar']) {
    await call('/v1/init/', '/v1/init', lang);
    await call('/v1/home/', '/v1/home', lang);
    const cats = await call('/v1/categories/', '/v1/categories', lang);
    const brands = await call('/v1/brands/', '/v1/brands?limit=100', lang);
    const prods = await call('/v1/products/', '/v1/products?limit=100', lang);
    const colls = await call('/v1/collections/', '/v1/collections?limit=100', lang);
    const recs = await call('/v1/recipes/', '/v1/recipes?limit=100', lang);
    await call('/v1/offers/', '/v1/offers', lang);
    await call('/v1/subscription-plans/', '/v1/subscription-plans', lang);
    if (lang === 'en') {
      slugs.categories = cats.results.data.map((x) => x.slug);
      slugs.brands = brands.results.data.map((x) => x.slug);
      slugs.products = prods.results.data.map((x) => x.slug);
      slugs.collections = colls.results.data.map((x) => x.slug);
      slugs.recipes = recs.results.data.map((x) => x.slug);
    }
    for (const s of slugs.categories) await call('/v1/categories/{slug}', `/v1/categories/${s}`, lang);
    for (const s of slugs.brands) await call('/v1/brands/{slug}', `/v1/brands/${s}`, lang);
    for (const s of slugs.collections) await call('/v1/collections/{slug}', `/v1/collections/${s}`, lang);
    for (const s of slugs.recipes) await call('/v1/recipes/{slug}', `/v1/recipes/${s}`, lang);
    for (const s of slugs.products) {
      await call('/v1/products/{slug}', `/v1/products/${s}`, lang);
      await call('/v1/products/{slug}/reviews', `/v1/products/${s}/reviews`, lang);
    }
    for (const p of ['about', 'contact', 'faq', 'privacy', 'terms']) await call('/v1/pages/{slug}', `/v1/pages/${p}`, lang);
  }
  // product list filters / sorts (en)
  const q = [
    'sort=newest', 'sort=price_asc', 'sort=price_desc', 'sort=name', 'sort=discount_desc',
    'onSale=true', 'inStock=true', 'inStock=false', 'minPrice=1000&maxPrice=3000', 'tag=best-seller',
    'search=rice', 'search=zzzznothing', 'page=2&limit=4', 'page=99&limit=4',
    ...slugs.categories.slice(0, 40).map((s) => 'categorySlug=' + s + '&limit=100'),
    ...slugs.brands.map((s) => 'brandSlug=' + s),
    ...slugs.collections.map((s) => 'collectionSlug=' + s),
  ];
  const filterStats = [];
  for (const qs of q) {
    const b = await call('/v1/products/', '/v1/products?' + qs, 'en');
    if (b && b.results) filterStats.push({ qs, total: b.results.pagination.total, rows: b.results.data.length, hasMore: b.results.pagination.hasMore, first: b.results.data.slice(0, 4).map((x) => `${x.slug}:${x.price}`) });
  }
  // failure paths
  await call('/v1/products/{slug}', '/v1/products/does-not-exist-xyz', 'en', 404);
  await call('/v1/products/{slug}', '/v1/products/does-not-exist-xyz', 'ar', 404);
  await call('/v1/categories/{slug}', '/v1/categories/does-not-exist-xyz', 'en', 404);
  await call('/v1/products/', '/v1/products?limit=500', 'en', 400);
  await call('/v1/products/', '/v1/products?sort=bogus', 'en', 400);
  // `pages/:slug` is an enum of the five CMS slugs in the spec: an unknown one fails validation.
  await call('/v1/pages/{slug}', '/v1/pages/does-not-exist-xyz', 'en', 400);

  if (process.env.REPORT_FILE) fs.writeFileSync(process.env.REPORT_FILE, JSON.stringify({ report, filterStats, slugs }, null, 1));
  const bad = report.filter((r) => r.errors.length);
  const extra = report.filter((r) => r.extras.length);
  process.exitCode = bad.length ? 1 : 0;
  console.log(`requests: ${report.length}  with spec errors: ${bad.length}  with undeclared fields: ${extra.length}`);
  for (const r of bad) console.log(`ERR  [${r.lang}] ${r.url}\n     ` + r.errors.join('\n     '));
  const ex = {};
  for (const r of extra) for (const e of r.extras) (ex[e] = ex[e] || new Set()).add(r.url.replace(/\/[a-z0-9-]+(\?.*)?$/, '/*'));
  for (const [k, v] of Object.entries(ex)) console.log(`EXTRA ${k}   @ ${[...v].slice(0, 3).join(', ')}`);
  console.log('\nFILTERS');
  for (const f of filterStats) console.log(`  ${f.qs.padEnd(48)} total=${f.total} rows=${f.rows} hasMore=${f.hasMore}  ${f.first.join(' ')}`);
})().catch((e) => { console.error('FATAL', e); process.exit(1); });
