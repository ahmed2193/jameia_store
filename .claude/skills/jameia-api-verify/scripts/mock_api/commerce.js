// Cart, delivery, orders and reviews for the mock jm3eia API.
// Required by server.js; every route answers the same envelope helpers.
//
// Admin knobs (all POST unless noted):
//   /__admin/cart/out-of-stock/:productId  -> that product is refused by
//                                             POST /v1/cart/items (OUT_OF_STOCK)
//                                             and flagged on the next GET /v1/cart
//   /__admin/cart/stock/:productId/:n      -> cap a product at n pieces
//                                             (a PATCH above it comes back reduced)
//   /__admin/cart/delay/:ms                -> every cart reply waits :ms
//   /__admin/cart/closed/:0|1              -> branchOpen flag of the cart
//   /__admin/cart/capacity/:0|1            -> capacityAvailable flag
//   /__admin/orders/advance/:orderId       -> moves the order one status forward
//   /__admin/orders/fail/:orderId          -> marks it delivery_failed
//   GET /__admin/orders                    -> the orders placed so far
const crypto = require('crypto');
const catalog = require('./catalog.js');

const oid = () => crypto.randomBytes(12).toString('hex');

const PRODUCTS = [
  { _id: 'p_rice', slug: 'basmati-rice-5kg', name: { en: 'Basmati rice 5kg', ar: 'أرز بسمتي ٥ كجم' }, type: 'standard', price: 3250, compareAt: 3900, stock: 40 },
  { _id: 'p_milk', slug: 'fresh-milk-1l', name: { en: 'Fresh milk 1L', ar: 'حليب طازج ١ لتر' }, type: 'standard', price: 850, stock: 60 },
  { _id: 'p_eggs', slug: 'eggs-30', name: { en: 'Eggs 30 pcs', ar: 'بيض ٣٠ حبة' }, type: 'standard', price: 2100, proPrice: 1900, stock: 25 },
  { _id: 'p_oil', slug: 'olive-oil-500ml', name: { en: 'Olive oil 500ml', ar: 'زيت زيتون ٥٠٠ مل' }, type: 'standard', price: 4500, stock: 12 },
  { _id: 'p_water', slug: 'water-pack', name: { en: 'Water 24 pack', ar: 'ماء ٢٤ عبوة' }, type: 'standard', price: 1200, stock: 80 },
];

const BRANCHES = [
  { _id: 'b_salmiya', name: { en: 'Salmiya', ar: 'السالمية' }, code: 'SLM', address: { en: 'Block 3, Salem Al Mubarak St', ar: 'قطعة ٣، شارع سالم المبارك' }, phone: '+96522221111', lat: 29.3339, lng: 48.0763, services: { delivery: true, pickup: true, express: true }, minOrder: 2000, etaMinutes: 45 },
  { _id: 'b_jabriya', name: { en: 'Jabriya', ar: 'الجابرية' }, code: 'JBR', address: { en: 'Block 1, Jabriya', ar: 'قطعة ١، الجابرية' }, phone: '+96522223333', lat: 29.3187, lng: 48.0247, services: { delivery: true, pickup: true, express: false }, minOrder: 2500, etaMinutes: 60 },
  { _id: 'b_dark', name: { en: 'Dark store', ar: 'مستودع' }, code: 'DRK', address: { en: 'Shuwaikh', ar: 'الشويخ' }, phone: '+96522224444', lat: 29.33, lng: 47.93, services: { delivery: true, pickup: false, express: true }, minOrder: 2000, etaMinutes: 30 },
];

const ORDER_FLOW = ['placed', 'confirmed', 'picking', 'ready', 'out_for_delivery', 'delivered'];

const state = {
  carts: new Map(), // owner key -> cart
  orders: [],
  reviews: [],
  outOfStock: new Set(),
  stockCap: new Map(),
  delay: 0,
  branchOpen: true,
  capacity: true,
};

/// The catalogue snapshot, in the shape the cart prices with: bilingual name,
/// real image, stock. Ids come from the same rows the app shows on home / PDP,
/// so anything addable in the UI is addable here.
const CATALOG = (() => {
  const byId = new Map();
  for (const lang of ['en', 'ar']) {
    for (const row of catalog.productsOf(lang)) {
      const known = byId.get(row._id) || {
        _id: row._id, slug: row.slug, name: {}, type: row.type,
        price: row.price, proPrice: row.proPrice || null, compareAt: row.compareAt || null,
        stock: row.stock, image: row.image || null, tags: row.tags || ['fresh'],
        unitOfSale: row.unitOfSale || 'piece',
        ratingAverage: row.ratingAverage || 0, ratingCount: row.ratingCount || 0,
      };
      known.name[lang] = row.name;
      byId.set(row._id, known);
    }
  }
  return byId;
})();

const product = (id) => CATALOG.get(id) || PRODUCTS.find((p) => p._id === id) || null;
const capOf = (id) => (state.stockCap.has(id) ? state.stockCap.get(id) : product(id).stock);

/// The cart of this caller: the customer's while signed in, else the guest
/// cart named by `X-Cart-Token` (issued on the first write).
function cartKey(req, authed) {
  if (authed) return 'customer';
  return 'guest:' + (req.headers['x-cart-token'] || 'anonymous');
}

function emptyCart(token) {
  return { cartToken: token, lines: [], coupon: null, loyaltyPoints: 0, express: false, mode: 'delivery', branchId: 'b_salmiya', addressId: null, slot: null };
}

function cartOf(req, authed) {
  const key = cartKey(req, authed);
  if (!state.carts.has(key)) {
    state.carts.set(key, emptyCart(key.startsWith('guest:') && req.headers['x-cart-token'] ? req.headers['x-cart-token'] : 'cart_' + crypto.randomBytes(4).toString('hex')));
  }
  return state.carts.get(key);
}

/// One `lines[]` row as the app reads it (money in fils, name resolved).
function lineOf(line, lang) {
  const p = product(line.productId);
  if (!p) return null;
  const max = capOf(p._id);
  const quantity = Math.min(line.quantity, max);
  return {
    key: line.key,
    quantity,
    maxQuantity: max,
    unitPrice: p.price,
    compareAt: p.compareAt || null,
    lineTotal: p.price * quantity,
    variantId: line.variantId || null,
    variantName: line.variantId ? '1 L' : null,
    product: cardOf(p, lang),
    issue: state.outOfStock.has(p._id)
      ? 'out_of_stock'
      : quantity < line.quantity
      ? 'quantity_reduced'
      : null,
  };
}

function cardOf(p, lang) {
  return {
    _id: p._id, slug: p.slug, name: p.name[lang] || p.name.en, type: p.type,
    price: p.price, proPrice: p.proPrice || null, compareAt: p.compareAt || null,
    image: p.image || `https://cdn.jm3eia.store/${p.slug}.png`, stock: capOf(p._id),
    tags: p.tags || ['fresh'], unitOfSale: p.unitOfSale || 'piece',
    ratingAverage: p.ratingAverage || 4.4, ratingCount: p.ratingCount || 18,
  };
}

const FREE_DELIVERY_AT = 10000;

/// The whole cart every `/v1/cart*` route answers with.
function cartPayload(cart, lang) {
  const lines = cart.lines.map((line) => lineOf(line, lang)).filter(Boolean);
  const subtotal = lines.reduce((sum, l) => sum + l.lineTotal, 0);
  const branch = BRANCHES.find((b) => b._id === cart.branchId) || BRANCHES[0];
  const couponDiscount = cart.coupon ? Math.round(subtotal * 0.1) : 0;
  const loyaltyDiscount = cart.loyaltyPoints ? Math.min(cart.loyaltyPoints, Math.round(subtotal / 2)) : 0;
  const offerDiscount = 0;
  const discount = couponDiscount + loyaltyDiscount + offerDiscount;
  const freeDelivery = subtotal >= FREE_DELIVERY_AT;
  const expressSurcharge = cart.express ? 750 : 0;
  const deliveryFee = cart.mode === 'pickup' || freeDelivery ? 0 : 500;
  const remaining = Math.max(0, FREE_DELIVERY_AT - subtotal);
  return {
    cartToken: cart.cartToken,
    itemCount: lines.reduce((sum, l) => sum + l.quantity, 0),
    fulfillmentMode: cart.mode,
    lines,
    offerLines: [],
    appliedOffers: freeDelivery
      ? [{ offerId: 'of_free_delivery', name: lang === 'ar' ? 'توصيل مجاني' : 'Free delivery', rewardType: 'free_delivery', discount: 500, reward: { type: 'free_delivery' } }]
      : [],
    offerProgress: freeDelivery
      ? []
      : [{ offerId: 'of_free_delivery', name: lang === 'ar' ? 'توصيل مجاني' : 'Free delivery', kind: 'subtotal', currentValue: subtotal, targetValue: FREE_DELIVERY_AT, remainingValue: remaining, reward: { type: 'free_delivery' } }],
    coupon: cart.coupon ? { code: cart.coupon, discount: couponDiscount } : null,
    loyalty: { pointsApplied: cart.loyaltyPoints, discount: loyaltyDiscount },
    expressOffered: branch.services.express && cart.mode === 'delivery',
    expressSelected: cart.express,
    expressEtaMinutes: 20,
    expressSurchargeOffered: 750,
    branchOpen: state.branchOpen,
    capacityAvailable: state.capacity,
    totals: {
      subtotal,
      couponDiscount,
      loyaltyDiscount,
      offerDiscount,
      discount,
      deliveryFee: deliveryFee + expressSurcharge,
      freeDelivery,
      total: Math.max(0, subtotal - discount) + deliveryFee + expressSurcharge,
      minOrder: branch.minOrder,
      meetsMinOrder: subtotal >= branch.minOrder,
      baseDeliveryFee: 500,
      expressSurcharge,
      etaMinutes: cart.express ? 20 : branch.etaMinutes,
    },
  };
}

/// `GET /v1/delivery/slots` — three days, the first window of each day full.
function slotDays(lang) {
  const days = [];
  for (let d = 0; d < 3; d++) {
    const date = new Date(Date.now() + d * 86400e3);
    const iso = date.toISOString().slice(0, 10);
    const slots = [['10:00', '12:00'], ['12:00', '14:00'], ['18:00', '20:00']].map(([start, end], i) => {
      const remaining = d === 0 && i === 0 ? 0 : 10 - i * 3;
      return {
        templateId: `t_${d}_${i}`, date: iso, start, end,
        startAt: `${iso}T${start}:00.000Z`, endAt: `${iso}T${end}:00.000Z`,
        label: `${start} - ${end}`, capacity: 10, booked: 10 - remaining,
        remaining, available: remaining > 0,
      };
    });
    days.push({ date: iso, label: d === 0 ? (lang === 'ar' ? 'اليوم' : 'Today') : iso, slots });
  }
  return days;
}

/// Turns the cart into an order (`POST /v1/orders`).
function placeOrder(cart, body, lang, customer) {
  const payload = cartPayload(cart, lang);
  const now = new Date().toISOString();
  const branch = BRANCHES.find((b) => b._id === cart.branchId) || BRANCHES[0];
  const address = (customer.addresses || []).find((a) => a._id === cart.addressId) || (customer.addresses || [])[0] || null;
  const slot = body.deliverySlot
    ? slotDays(lang).flatMap((d) => d.slots).find((s) => s.templateId === body.deliverySlot.templateId && s.date === body.deliverySlot.date) || null
    : null;
  const order = {
    _id: oid(),
    orderNumber: `JM-${2000 + state.orders.length}`,
    status: 'placed',
    statusTimeline: [{ at: now, status: 'placed' }],
    fulfillmentMode: cart.mode,
    branch: { id: branch._id, name: branch.name },
    zone: cart.mode === 'delivery' ? { id: 'z1', name: { en: 'Zone 1', ar: 'المنطقة ١' } } : null,
    address: cart.mode === 'delivery' && address
      ? { id: address._id, label: address.label, city: address.city, block: address.block, street: address.street, building: address.building, floor: address.floor, apartment: address.apartment, phone: address.phone, lat: address.lat, lng: address.lng }
      : null,
    lines: payload.lines.map((l) => ({
      key: l.key,
      product: { id: l.product._id, name: product(l.product._id).name, image: l.product.image, type: l.product.type },
      variant: l.variantId ? { id: l.variantId, name: { en: '1 L', ar: '١ لتر' }, sku: 'SKU-1' } : null,
      quantity: l.quantity, unitPrice: l.unitPrice, lineTotal: l.lineTotal,
    })),
    offerLines: [],
    appliedOffers: payload.appliedOffers.map((o) => ({ id: o.offerId, name: { en: o.name, ar: o.name }, rewardType: o.rewardType, discount: o.discount })),
    coupon: payload.coupon,
    loyalty: { pointsRedeemed: payload.loyalty.pointsApplied, discount: payload.loyalty.discount, pointsEarned: Math.round(payload.totals.total / 100) },
    offerDiscount: payload.totals.offerDiscount,
    proDiscount: 0,
    subtotal: payload.totals.subtotal,
    discount: payload.totals.discount,
    deliveryFee: payload.totals.deliveryFee,
    total: payload.totals.total,
    express: cart.express,
    etaMinutes: payload.totals.etaMinutes,
    deliverySlot: slot ? { templateId: slot.templateId, date: slot.date, start: slot.start, end: slot.end, startAt: slot.startAt, endAt: slot.endAt } : null,
    payment: { method: body.paymentMethod, status: body.paymentMethod === 'wallet' ? 'paid' : 'pending', walletUsed: body.paymentMethod === 'wallet' ? payload.totals.total : 0 },
    picking: null,
    delivery: null,
    cancellation: null,
    notes: body.notes || '',
    createdAt: now,
    updatedAt: now,
  };
  state.orders.unshift(order);
  cart.lines = [];
  cart.coupon = null;
  cart.loyaltyPoints = 0;
  cart.express = false;
  return order;
}

/// Moves an order one step along the flow and fills the stage details.
function advance(order) {
  const index = ORDER_FLOW.indexOf(order.status);
  if (index < 0 || index === ORDER_FLOW.length - 1) return order;
  order.status = ORDER_FLOW[index + 1];
  const now = new Date().toISOString();
  order.statusTimeline.push({ at: now, status: order.status });
  order.updatedAt = now;
  if (order.status === 'picking') {
    order.picking = { picker: { _id: 'u_picker', name: 'Sara' }, startedAt: now, lines: [], unavailableLines: [], substitutedLines: [] };
  }
  if (order.status === 'out_for_delivery') {
    order.delivery = { driver: { _id: 'u_driver', name: 'Ali' }, pickedUpAt: now, deliveredAt: null, attempts: [] };
  }
  if (order.status === 'delivered') {
    order.delivery = { ...(order.delivery || { driver: { _id: 'u_driver', name: 'Ali' }, attempts: [] }), deliveredAt: now };
    order.payment.status = 'paid';
  }
  return order;
}

module.exports = { PRODUCTS, BRANCHES, ORDER_FLOW, state, oid, product, capOf, cardOf, cartOf, cartKey, cartPayload, slotDays, placeOrder, advance };
