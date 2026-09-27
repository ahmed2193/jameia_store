// The `/v1/cart*`, `/v1/delivery/*`, `/v1/orders*` and `/v1/reviews` routes
// of the mock API. `handleCommerce` answers the request and returns true when
// it owned the path, so server.js can fall through to its own routes.
const commerce = require('./commerce.js');

const { state, BRANCHES, ORDER_FLOW, cartOf, cartPayload, slotDays, placeOrder, advance, product, oid } = commerce;

const CANCEL_REASONS = ['changed_mind', 'ordered_by_mistake', 'too_slow', 'found_elsewhere', 'other'];

function handleAdmin(pathname, ok) {
  const oos = pathname.match(/^\/__admin\/cart\/out-of-stock\/([\w-]+)$/);
  if (oos) {
    state.outOfStock.has(oos[1]) ? state.outOfStock.delete(oos[1]) : state.outOfStock.add(oos[1]);
    return ok({ outOfStock: [...state.outOfStock] });
  }
  const stock = pathname.match(/^\/__admin\/cart\/stock\/([\w-]+)\/(\d+)$/);
  if (stock) {
    state.stockCap.set(stock[1], Number(stock[2]));
    return ok({ [stock[1]]: Number(stock[2]) });
  }
  const delay = pathname.match(/^\/__admin\/cart\/delay\/(\d+)$/);
  if (delay) { state.delay = Number(delay[1]); return ok({ delay: state.delay }); }
  const closed = pathname.match(/^\/__admin\/cart\/closed\/([01])$/);
  if (closed) { state.branchOpen = closed[1] === '0'; return ok({ branchOpen: state.branchOpen }); }
  const capacity = pathname.match(/^\/__admin\/cart\/capacity\/([01])$/);
  if (capacity) { state.capacity = capacity[1] === '1'; return ok({ capacityAvailable: state.capacity }); }
  const step = pathname.match(/^\/__admin\/orders\/advance\/([0-9a-f]{24})$/);
  if (step) {
    const order = state.orders.find((o) => o._id === step[1]);
    return ok(order ? advance(order) : { error: 'unknown order' });
  }
  const failed = pathname.match(/^\/__admin\/orders\/fail\/([0-9a-f]{24})$/);
  if (failed) {
    const order = state.orders.find((o) => o._id === failed[1]);
    if (order) {
      order.status = 'delivery_failed';
      order.statusTimeline.push({ at: new Date().toISOString(), status: 'delivery_failed' });
      order.delivery = { ...(order.delivery || { driver: { _id: 'u_driver', name: 'Ali' } }), attempts: [{ at: new Date().toISOString(), outcome: 'failed', note: 'nobody home', by: 'driver' }], lastFailureReason: 'customer_absent' };
    }
    return ok(order || { error: 'unknown order' });
  }
  if (pathname === '/__admin/orders') return ok(state.orders);
  return false;
}

/// The cart routes. [api] carries the envelope helpers and the request facts.
function handleCart(api) {
  const { req, pathname, body, ok, fail, lang, authed } = api;
  const cart = cartOf(req, authed);
  const reply = (statusMessage = 'SUCCESS') => ok(cartPayload(cart, lang), statusMessage);

  if (pathname === '/v1/cart' && req.method === 'GET') return reply('DATA_LOADED');
  if (pathname === '/v1/cart' && req.method === 'DELETE') {
    cart.lines = [];
    cart.coupon = null;
    cart.loyaltyPoints = 0;
    return reply('DELETED');
  }
  if (pathname === '/v1/cart/items' && req.method === 'POST') {
    const items = Array.isArray(body.items) ? body.items : null;
    if (!items || !items.length || items.length > 50) {
      return fail(400, 'VALIDATION_ERROR', lang === 'ar' ? 'فشل التحقق' : 'Validation failed', [{ key: 'items', message: 'must have 1..50 rows' }]);
    }
    for (const item of items) {
      if (!product(item.productId)) return fail(404, 'RESOURCE_NOT_FOUND', lang === 'ar' ? 'المنتج غير موجود' : 'Product not found');
      if (state.outOfStock.has(item.productId)) {
        return fail(400, 'OUT_OF_STOCK', lang === 'ar' ? 'المنتج غير متوفر' : 'This product is out of stock');
      }
    }
    for (const item of items) {
      const quantity = Math.max(1, Number(item.quantity || 1));
      const existing = cart.lines.find((l) => l.productId === item.productId && (l.variantId || null) === (item.variantId || null));
      if (existing) existing.quantity += quantity;
      else cart.lines.push({ key: 'ln_' + oid().slice(0, 8), productId: item.productId, variantId: item.variantId || null, quantity });
    }
    return reply('CREATED');
  }
  const itemMatch = pathname.match(/^\/v1\/cart\/items\/([\w-]+)$/);
  if (itemMatch) {
    const line = cart.lines.find((l) => l.key === itemMatch[1]);
    if (!line) return fail(404, 'RESOURCE_NOT_FOUND', lang === 'ar' ? 'السطر غير موجود' : 'Line not found');
    if (req.method === 'DELETE') {
      cart.lines = cart.lines.filter((l) => l !== line);
      return reply('DELETED');
    }
    if (req.method === 'PATCH') {
      const quantity = Number(body.quantity);
      if (!Number.isInteger(quantity) || quantity < 0) {
        return fail(400, 'VALIDATION_ERROR', lang === 'ar' ? 'فشل التحقق' : 'Validation failed', [{ key: 'quantity', message: 'must be >= 0' }]);
      }
      if (quantity === 0) cart.lines = cart.lines.filter((l) => l !== line);
      else line.quantity = quantity;
      return reply('UPDATED');
    }
  }
  if (pathname === '/v1/cart/coupon') {
    if (req.method === 'POST') {
      const code = typeof body.code === 'string' ? body.code.trim() : '';
      if (code.length < 2 || code.length > 32) {
        return fail(400, 'VALIDATION_ERROR', lang === 'ar' ? 'فشل التحقق' : 'Validation failed', [{ key: 'code', message: 'must be 2..32 characters' }]);
      }
      if (code.toUpperCase() !== 'WELCOME') {
        return fail(400, 'COUPON_INVALID', lang === 'ar' ? 'رمز غير صالح' : 'This coupon is not valid');
      }
      cart.coupon = code.toUpperCase();
      return reply('UPDATED');
    }
    if (req.method === 'DELETE') { cart.coupon = null; return reply('DELETED'); }
  }
  if (pathname === '/v1/cart/loyalty') {
    if (req.method === 'POST') {
      const points = Number(body.points);
      if (!Number.isInteger(points) || points < 1) {
        return fail(400, 'VALIDATION_ERROR', lang === 'ar' ? 'فشل التحقق' : 'Validation failed', [{ key: 'points', message: 'must be >= 1' }]);
      }
      if (!authed) return fail(401, 'AUTHENTICATION_REQUIRED', lang === 'ar' ? 'سجّل الدخول للمتابعة' : 'Sign in to continue');
      cart.loyaltyPoints = points;
      return reply('UPDATED');
    }
    if (req.method === 'DELETE') { cart.loyaltyPoints = 0; return reply('DELETED'); }
  }
  if (pathname === '/v1/cart/express' && req.method === 'POST') {
    cart.express = body.enabled === true;
    return reply('UPDATED');
  }
  return fail(404, 'RESOURCE_NOT_FOUND', 'Not found');
}

/// The delivery routes: branches, slots and the two selection calls.
function handleDelivery(api) {
  const { req, pathname, body, ok, fail, lang, authed, customer } = api;
  const cart = cartOf(req, authed);

  if (pathname === '/v1/delivery/branches' && req.method === 'GET') {
    return ok({
      data: BRANCHES.map((b) => ({
        _id: b._id, name: b.name[lang] || b.name.en, code: b.code,
        address: b.address[lang] || b.address.en, phone: b.phone, lat: b.lat, lng: b.lng,
        services: b.services, minOrder: b.minOrder, etaMinutes: b.etaMinutes,
      })),
    }, 'DATA_LOADED');
  }
  if (pathname === '/v1/delivery/slots' && req.method === 'GET') {
    return ok({ data: slotDays(lang) }, 'DATA_LOADED');
  }
  if (pathname === '/v1/delivery/select-branch' && req.method === 'POST') {
    const branch = BRANCHES.find((b) => b._id === body.branchId);
    if (!branch) return fail(404, 'RESOURCE_NOT_FOUND', lang === 'ar' ? 'الفرع غير موجود' : 'Branch not found');
    if (!branch.services.pickup) return fail(400, 'VALIDATION_ERROR', lang === 'ar' ? 'الفرع لا يدعم الاستلام' : 'This branch has no pickup');
    cart.mode = 'pickup';
    cart.branchId = branch._id;
    cart.express = false;
    return ok({
      mode: 'pickup', branchId: branch._id, branchName: branch.name[lang] || branch.name.en,
      address: branch.address[lang] || branch.address.en, deliveryFee: 0,
      minOrder: branch.minOrder, etaMinutes: 20,
    }, 'UPDATED');
  }
  if (pathname === '/v1/delivery/select-address' && req.method === 'POST') {
    if (!authed) return fail(401, 'AUTHENTICATION_REQUIRED', lang === 'ar' ? 'سجّل الدخول للمتابعة' : 'Sign in to continue');
    const address = (customer.addresses || []).find((a) => a._id === body.addressId);
    if (!address) return fail(404, 'RESOURCE_NOT_FOUND', lang === 'ar' ? 'العنوان غير موجود' : 'Address not found');
    const branch = BRANCHES[0];
    cart.mode = 'delivery';
    cart.branchId = branch._id;
    cart.addressId = address._id;
    return ok({
      mode: 'delivery', addressId: address._id, addressLabel: address.label,
      paciAreaId: address.areaId, areaName: address.city, governorateName: 'Capital',
      lat: address.lat, lng: address.lng, branchId: branch._id,
      branchName: branch.name[lang] || branch.name.en, zoneId: 'z1',
      zoneName: lang === 'ar' ? 'المنطقة ١' : 'Zone 1', deliveryFee: 500,
      minOrder: branch.minOrder, etaMinutes: branch.etaMinutes,
    }, 'UPDATED');
  }
  return fail(404, 'RESOURCE_NOT_FOUND', 'Not found');
}

/// `POST /v1/orders`, the list, one order and the cancel call.
function handleOrders(api) {
  const { req, pathname, query, body, ok, fail, lang, authed, customer } = api;
  if (!authed) return fail(401, 'AUTHENTICATION_REQUIRED', lang === 'ar' ? 'سجّل الدخول للمتابعة' : 'Sign in to continue');
  const cart = cartOf(req, authed);

  if (pathname === '/v1/orders' && req.method === 'POST') {
    if (!cart.lines.length) return fail(400, 'CART_EMPTY', lang === 'ar' ? 'سلتك فارغة' : 'Your cart is empty');
    if (!['cod', 'wallet'].includes(body.paymentMethod)) {
      return fail(400, 'VALIDATION_ERROR', lang === 'ar' ? 'فشل التحقق' : 'Validation failed', [{ key: 'paymentMethod', message: 'must be cod or wallet' }]);
    }
    if (typeof body.notes === 'string' && body.notes.length > 256) {
      return fail(400, 'VALIDATION_ERROR', lang === 'ar' ? 'فشل التحقق' : 'Validation failed', [{ key: 'notes', message: 'must NOT have more than 256 characters' }]);
    }
    const payload = cartPayload(cart, lang);
    if (!payload.totals.meetsMinOrder) return fail(400, 'MIN_ORDER_NOT_MET', lang === 'ar' ? 'لم يتم الوصول للحد الأدنى' : 'Minimum order not met');
    if (!payload.branchOpen) return fail(400, 'BRANCH_CLOSED', lang === 'ar' ? 'الفرع مغلق' : 'The branch is closed');
    const order = placeOrder(cart, body, lang, customer);
    if (order.payment.method === 'wallet') customer.wallet = Math.max(0, customer.wallet - order.total);
    return ok(order, 'CREATED');
  }
  if (pathname === '/v1/orders' && req.method === 'GET') {
    const page = Math.max(1, Number(query.page || 1));
    const limit = Math.min(100, Math.max(1, Number(query.limit || 20)));
    const all = query.search
      ? state.orders.filter((o) => o.orderNumber.includes(String(query.search)))
      : state.orders;
    return ok({
      data: all.slice((page - 1) * limit, page * limit),
      pagination: { total: all.length, page, limit, hasMore: page * limit < all.length },
    }, 'DATA_LOADED');
  }
  const cancelMatch = pathname.match(/^\/v1\/orders\/([0-9a-f]{24})\/cancel$/);
  if (cancelMatch && req.method === 'POST') {
    const order = state.orders.find((o) => o._id === cancelMatch[1]);
    if (!order) return fail(404, 'RESOURCE_NOT_FOUND', lang === 'ar' ? 'الطلب غير موجود' : 'Order not found');
    if (!CANCEL_REASONS.includes(body.reason)) {
      return fail(400, 'VALIDATION_ERROR', lang === 'ar' ? 'فشل التحقق' : 'Validation failed', [{ key: 'reason', message: `must be one of ${CANCEL_REASONS.join(', ')}` }]);
    }
    if (!['placed', 'confirmed', 'picking'].includes(order.status)) {
      return fail(400, 'ORDER_NOT_CANCELLABLE', lang === 'ar' ? 'لا يمكن إلغاء هذا الطلب' : 'This order can no longer be cancelled');
    }
    const now = new Date().toISOString();
    order.status = 'cancelled';
    order.statusTimeline.push({ at: now, status: 'cancelled' });
    order.cancellation = { reason: body.reason, cancelledBy: 'customer', cancelledAt: now, note: body.note || '' };
    order.updatedAt = now;
    return ok(order, 'UPDATED');
  }
  const detailMatch = pathname.match(/^\/v1\/orders\/([0-9a-f]{24})$/);
  if (detailMatch && req.method === 'GET') {
    const order = state.orders.find((o) => o._id === detailMatch[1]);
    if (!order) return fail(404, 'RESOURCE_NOT_FOUND', lang === 'ar' ? 'الطلب غير موجود' : 'Order not found');
    return ok(order, 'DATA_LOADED');
  }
  return fail(404, 'RESOURCE_NOT_FOUND', 'Not found');
}

/// `POST /v1/reviews` and `PATCH /v1/reviews/:id`.
function handleReviews(api) {
  const { req, pathname, body, ok, fail, lang, authed } = api;
  if (!authed) return fail(401, 'AUTHENTICATION_REQUIRED', lang === 'ar' ? 'سجّل الدخول للمتابعة' : 'Sign in to continue');
  const rating = Number(body.rating);
  const badRating = !Number.isInteger(rating) || rating < 1 || rating > 5;
  if (pathname === '/v1/reviews' && req.method === 'POST') {
    if (!body.productId || !body.orderId || badRating) {
      return fail(400, 'VALIDATION_ERROR', lang === 'ar' ? 'فشل التحقق' : 'Validation failed', [{ key: 'rating', message: 'must be 1..5' }]);
    }
    const order = state.orders.find((o) => o._id === body.orderId);
    if (!order) return fail(404, 'RESOURCE_NOT_FOUND', lang === 'ar' ? 'الطلب غير موجود' : 'Order not found');
    if (order.status !== 'delivered') {
      return fail(400, 'ORDER_NOT_DELIVERED', lang === 'ar' ? 'لا يمكن التقييم قبل التوصيل' : 'You can review after delivery');
    }
    const review = { _id: oid(), productId: body.productId, orderId: body.orderId, rating, title: body.title || '', body: body.body || '' };
    state.reviews.push(review);
    return ok({ message: lang === 'ar' ? 'شكرًا لتقييمك' : 'Thanks for your review', reviewId: review._id }, 'CREATED');
  }
  const editMatch = pathname.match(/^\/v1\/reviews\/([0-9a-f]{24})$/);
  if (editMatch && req.method === 'PATCH') {
    const review = state.reviews.find((r) => r._id === editMatch[1]);
    if (!review) return fail(404, 'RESOURCE_NOT_FOUND', 'Not found');
    if ('rating' in body && badRating) {
      return fail(400, 'VALIDATION_ERROR', 'Validation failed', [{ key: 'rating', message: 'must be 1..5' }]);
    }
    Object.assign(review, body);
    return ok({ message: 'Updated', reviewId: review._id }, 'UPDATED');
  }
  return fail(404, 'RESOURCE_NOT_FOUND', 'Not found');
}

/// True when [pathname] belongs to this module (the reply was already sent
/// or is on its way after the configured delay).
function handleCommerce(api) {
  const { pathname } = api;
  const run = (handler) => {
    if (state.delay > 0) setTimeout(() => handler(api), state.delay);
    else handler(api);
    return true;
  };
  if (pathname === '/v1/cart' || pathname.startsWith('/v1/cart/')) return run(handleCart);
  if (pathname.startsWith('/v1/delivery/')) return run(handleDelivery);
  if (pathname === '/v1/orders' || pathname.startsWith('/v1/orders/')) return run(handleOrders);
  if (pathname === '/v1/reviews' || pathname.startsWith('/v1/reviews/')) return run(handleReviews);
  return false;
}

module.exports = { handleAdmin, handleCommerce, CANCEL_REASONS, commerce };
