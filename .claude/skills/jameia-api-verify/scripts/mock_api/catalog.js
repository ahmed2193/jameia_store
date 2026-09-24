// Read-only catalogue for the mock jm3eia API: home, categories, brands,
// collections, products (+ detail, reviews), recipes, offers, pages.
//
// The rows are a snapshot of the live catalogue (`catalog_fixtures.json`,
// captured per language), so the app parses exactly what production sends and
// the cart can be filled with real product ids. `GET /v1/products` filters and
// paginates the snapshot in memory the way the backend does.
const FIXTURES = require('./catalog_fixtures.json');

const langOf = (lang) => (FIXTURES[`${lang}/home`] ? lang : 'en');

/// `results` of a captured route, e.g. `pick('en', 'products/red-apples')`.
const pick = (lang, key) => FIXTURES[`${langOf(lang)}/${key}`];

/// Every product row of the snapshot, list shape (what `GET /v1/products` returns).
const productsOf = (lang) => (pick(lang, 'products') || { data: [] }).data;

/// The detail row (`GET /v1/products/:slug`) — carries brand, category, tags.
const detailOf = (lang, slug) => pick(lang, `products/${slug}`);

/// A product by `_id`, from any language, so the cart can price a line.
function productById(id) {
  for (const lang of ['en', 'ar']) {
    const hit = productsOf(lang).find((p) => p._id === id);
    if (hit) return hit;
  }
  return null;
}

const lower = (value) => String(value == null ? '' : value).toLowerCase();

const SORTS = {
  newest: (a, b) => lower(a.slug).localeCompare(lower(b.slug)),
  price_asc: (a, b) => a.price - b.price,
  price_desc: (a, b) => b.price - a.price,
  name: (a, b) => lower(a.name).localeCompare(lower(b.name)),
  discount_desc: (a, b) => discount(b) - discount(a),
};

const discount = (p) => (p.compareAt && p.compareAt > p.price ? p.compareAt - p.price : 0);

/// The slugs a product belongs to, read from its detail row (the list row has
/// neither brand nor category).
function facetsOf(lang, product) {
  const detail = detailOf(lang, product.slug) || {};
  return {
    category: detail.category ? detail.category.slug : null,
    brand: detail.brand ? detail.brand.slug : null,
    tags: Array.isArray(product.tags) ? product.tags : [],
  };
}

/// `GET /v1/products` — search / categorySlug / brandSlug / tag / inStock /
/// onSale / minPrice / maxPrice / sort / page / limit, same names as the app sends.
function listProducts(lang, query) {
  const page = Math.max(1, Number(query.page || 1));
  const limit = Math.min(100, Math.max(1, Number(query.limit || 20)));
  const search = lower(query.search).trim();
  let rows = productsOf(lang).slice();
  if (search) rows = rows.filter((p) => lower(p.name).includes(search) || lower(p.slug).includes(search));
  if (query.categorySlug || query.brandSlug || query.tag) {
    rows = rows.filter((p) => {
      const facets = facetsOf(lang, p);
      if (query.categorySlug && facets.category !== query.categorySlug) return false;
      if (query.brandSlug && facets.brand !== query.brandSlug) return false;
      if (query.tag && !facets.tags.includes(query.tag)) return false;
      return true;
    });
  }
  if (query.collectionSlug) {
    const collection = pick(lang, `collections/${query.collectionSlug}`);
    const ids = new Set(((collection && collection.products) || []).map((p) => p._id));
    rows = ids.size ? rows.filter((p) => ids.has(p._id)) : [];
  }
  if (String(query.inStock) === 'true') rows = rows.filter((p) => Number(p.stock) > 0);
  if (String(query.onSale) === 'true') rows = rows.filter((p) => discount(p) > 0);
  if (query.minPrice) rows = rows.filter((p) => p.price >= Number(query.minPrice));
  if (query.maxPrice) rows = rows.filter((p) => p.price <= Number(query.maxPrice));
  if (SORTS[query.sort]) rows.sort(SORTS[query.sort]);
  const total = rows.length;
  return {
    data: rows.slice((page - 1) * limit, page * limit),
    pagination: { total, page, limit, hasMore: page * limit < total },
  };
}

/// One-segment listings answered straight from the snapshot.
const LISTS = ['categories', 'brands', 'collections', 'recipes', 'offers', 'subscription-plans'];

/// Handles a catalogue GET. Returns true when it answered.
function handleCatalog({ pathname, query, method, lang, ok, fail }) {
  if (method !== 'GET' || !pathname.startsWith('/v1/')) return false;
  const rest = pathname.slice('/v1/'.length).replace(/\/+$/, '');
  const parts = rest.split('/');

  if (rest === 'home') return ok(pick(lang, 'home'), 'DATA_LOADED'), true;
  if (rest === 'products') return ok(listProducts(lang, query), 'DATA_LOADED'), true;
  if (LISTS.includes(rest)) return ok(pick(lang, rest), 'DATA_LOADED'), true;

  if (parts[0] === 'products' && parts.length === 3 && parts[2] === 'reviews') {
    const reviews = pick(lang, `products/${parts[1]}/reviews`);
    if (!reviews) return fail(404, 'RESOURCE_NOT_FOUND', 'Not found'), true;
    return ok(reviews, 'DATA_LOADED'), true;
  }
  if (parts.length === 2 && ['products', 'categories', 'brands', 'collections', 'recipes', 'pages'].includes(parts[0])) {
    const row = pick(lang, `${parts[0]}/${parts[1]}`);
    if (!row) return fail(404, 'RESOURCE_NOT_FOUND', lang === 'ar' ? 'غير موجود' : 'Not found'), true;
    return ok(row, 'DATA_LOADED'), true;
  }
  return false;
}

module.exports = { handleCatalog, productById, productsOf, detailOf };
