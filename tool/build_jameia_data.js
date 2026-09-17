// Transforms the captured jm3eia v5 API responses (assets/data/dummy_data/*.json)
// into the JameiaMart dataset schema (assets/data/jameia_data.json) so the Jameia
// UI renders REAL content (Arabic grocery names, real media.jm3eia.com images,
// real KD prices + discounts). Only the fields the UI needs are extracted.
//
// Run:  node tool/build_jameia_data.js   (from the project root)
//
// Keeps user/kingkong/filters/addresses/coupons/orders from the existing
// jameia_data.json; replaces shops + banners with real data.

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const DD = path.join(ROOT, 'assets', 'data', 'dummy_data');
const OUT = path.join(ROOT, 'assets', 'data', 'jameia_data.json');

const captures = []
  .concat(JSON.parse(fs.readFileSync(path.join(DD, 'home_capture.json'), 'utf8')))
  .concat(JSON.parse(fs.readFileSync(path.join(DD, 'store_category_data.json'), 'utf8')));

const dataOf = (c) => (c && c.data && c.data.results && c.data.results.data) || null;

// ── Normalize a raw product into the clone's Product schema ───────────────────
function normProduct(p, i) {
  if (!p || !p.name || !p.picture) return null;
  const price = parseFloat(p.price);
  if (!(price > 0)) return null;
  if (p.availability === false) return null;
  const old = parseFloat(p.old_price || '0');
  // deterministic soldCount (no RNG, stable builds)
  const sold = 50 + (Math.round(price * 1000) * 7 + i * 13) % 4800;
  return {
    id: String(p.sku || p._id || ('p' + i)),
    name: String(p.name).trim(),
    image: p.picture,
    price: Math.round(price * 1000) / 1000,
    originalPrice: old > price ? Math.round(old * 1000) / 1000 : 0,
    desc: '',
    soldCount: sold,
    kcal: 0,
  };
}

// ── Gather features (name + product list) deduped by name ─────────────────────
const featureByName = new Map();
for (const c of captures) {
  if (!/\/v5\/feature/.test(c.url || '')) continue;
  const arr = dataOf(c);
  if (!arr) continue;
  for (const f of arr) {
    if (!f || !f.name || !Array.isArray(f.products)) continue;
    const name = String(f.name).trim();
    if (featureByName.has(name)) continue;
    const seen = new Set();
    const prods = [];
    f.products.forEach((p, i) => {
      const n = normProduct(p, i);
      if (n && !seen.has(n.id)) { seen.add(n.id); prods.push(n); }
    });
    if (prods.length >= 4) featureByName.set(name, prods);
  }
}

// Also pull a big spare product pool (rank/category responses) to pad thin shops.
const poolSeen = new Set();
const pool = [];
for (const c of captures) {
  if (!/\/v5\/product\//.test(c.url || '')) continue;
  const arr = dataOf(c);
  if (!arr) continue;
  arr.forEach((p, i) => {
    const n = normProduct(p, i);
    if (n && !poolSeen.has(n.id)) { poolSeen.add(n.id); pool.push(n); }
  });
}

// ── Build shops from the richest features ─────────────────────────────────────
const features = [...featureByName.entries()].sort((a, b) => b[1].length - a[1].length);
const deliveryTimes = ['15-25 min', '20-30 min', '25-35 min', '30-40 min'];
const sectionTitles = ['Top picks', 'Offers', 'Popular', 'Best sellers', 'New arrivals', 'More'];
const MAX_SHOPS = 14;
const chunk = (a, n) => { const o = []; for (let i = 0; i < a.length; i += n) o.push(a.slice(i, i + n)); return o; };

let poolCursor = 0;
const shops = [];
for (let i = 0; i < Math.min(features.length, MAX_SHOPS); i++) {
  const [name, prodsRaw] = features[i];
  let prods = prodsRaw.slice(0, 40);
  // pad to a reasonable menu if thin
  while (prods.length < 8 && poolCursor < pool.length) {
    const cand = pool[poolCursor++];
    if (!prods.some((x) => x.id === cand.id)) prods.push(cand);
  }
  const sections = chunk(prods, 8).map((items, si) => ({
    title: sectionTitles[si % sectionTitles.length],
    products: items,
  }));
  const fee = i % 3 === 0 ? 0.0 : 0.5;
  const cover = prods[0] ? prods[0].image : '';
  const logo = (prods[1] || prods[0] || {}).image || '';
  shops.push({
    id: 's' + (i + 1),
    name,
    logo,
    cover,
    kind: 'grocery',
    rating: Math.round((42 + (i * 7) % 8)) / 10,
    ratingCount: 180 + (i * 137) % 3200,
    deliveryFee: fee,
    deliveryTime: deliveryTimes[i % deliveryTimes.length],
    distanceKm: Math.round((6 + (i * 4) % 35)) / 10,
    minOrder: [2, 3, 4, 5][i % 4],
    tags: ['Grocery', 'Offers', 'Daily'].slice(0, 2 + (i % 2)),
    promo: fee === 0 ? 'Free delivery' : (prods.some((p) => p.originalPrice) ? 'Deals' : ''),
    freeDelivery: fee === 0,
    sponsored: i % 5 === 0,
    sections,
  });
}

// ── Banners from the top features ─────────────────────────────────────────────
const bg = ['#FFE41F', '#00B080', '#FF5324'];
const banners = features.slice(0, 3).map(([name, prods], i) => ({
  id: 'b' + (i + 1),
  title: name,
  subtitle: 'Limited time',
  image: prods[0] ? prods[0].image : '',
  bg: bg[i % bg.length],
}));

// ── Merge into existing dataset (keep the rest) ───────────────────────────────
const existing = JSON.parse(fs.readFileSync(OUT, 'utf8'));
existing.shops = shops;
existing.banners = banners.length ? banners : existing.banners;

fs.writeFileSync(OUT, JSON.stringify(existing, null, 2), 'utf8');
const totalProducts = shops.reduce((s, sh) => s + sh.sections.reduce((a, x) => a + x.products.length, 0), 0);
console.log('Wrote ' + OUT);
console.log('shops=' + shops.length + ' banners=' + banners.length + ' products=' + totalProducts + ' (featurePool=' + featureByName.size + ' sparePool=' + pool.length + ')');
