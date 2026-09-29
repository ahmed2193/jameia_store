// The `/v1/support/*` routes of the mock API (the order help page:
// "Get help with this order"). `handleSupport` answers the request and
// returns true when it owned the path, so server.js can fall through.
//   GET  /v1/support/categories          -> {data: [category]}  (public; the live taxonomy, captured 2026-09-28)
//   POST /v1/support/tickets (Bearer)    -> {message, ticketId} (ticketId = ObjectId)
//     subject 1..200, category one of the keys, subcategory a topic of that
//     category (or null), body 1..4000; orderId (ObjectId) required when the
//     category / topic requireOrder, productIds (ObjectId[] ≥ 1) when it
//     requireProducts. Opening a ticket adds an unread `support.ticket_created`
//     notification (pushed over SSE).
// Knobs:
//   POST /__admin/support/fail/:status/:n -> next n support requests answer :status
//        (500 INTERNAL_ERROR, 404 RESOURCE_NOT_FOUND, 400 VALIDATION_ERROR; tickets: after the Bearer check)
//   POST /__admin/support/delay/:ms       -> support replies wait :ms (the busy overlay; a double tap → one ticket)
//   GET  /__admin/support/tickets         -> the tickets opened so far (the exact bodies the app sent)
const crypto = require('crypto');

const oid = () => crypto.randomBytes(12).toString('hex');
const OBJECT_ID = /^[0-9a-fA-F]{24}$/;
const FAIL_CODES = { 400: 'VALIDATION_ERROR', 404: 'RESOURCE_NOT_FOUND', 500: 'INTERNAL_ERROR', 503: 'SERVICE_UNAVAILABLE' };

const topic = (key, requireOrder, requireProducts) => ({ key, requireOrder, requireProducts });
const CATEGORIES = [
  { key: 'order', requireOrder: true, requireProducts: false, children: [
    topic('missing_items', true, true), topic('wrong_items', true, true),
    topic('not_received', true, false), topic('quantity', true, true)] },
  { key: 'delivery', requireOrder: true, requireProducts: false, children: [
    topic('late', true, false), topic('driver', true, false),
    topic('wrong_address', true, false), topic('failed', true, false)] },
  { key: 'payment', requireOrder: true, requireProducts: false, children: [
    topic('charge_dispute', true, false), topic('double_charge', true, false), topic('not_processed', true, false)] },
  { key: 'wallet', requireOrder: false, requireProducts: false, children: [
    topic('balance', false, false), topic('credit_missing', false, false), topic('refund_to_wallet', false, false)] },
  { key: 'account', requireOrder: false, requireProducts: false, children: [
    topic('login', false, false), topic('password_reset', false, false),
    topic('profile', false, false), topic('account_deletion', false, false)] },
  { key: 'product', requireOrder: true, requireProducts: true, children: [
    topic('damaged', true, true), topic('expired', true, true), topic('quality', true, true)] },
  { key: 'subscription', requireOrder: false, requireProducts: false, children: [
    topic('billing', false, false), topic('cancellation', false, false), topic('access', false, false)] },
  { key: 'other', requireOrder: false, requireProducts: false, children: [] },
];

const state = { tickets: [], fail: { status: 500, n: 0 }, delay: 0 };

function handleSupportAdmin(pathname, ok) {
  const failKnob = pathname.match(/^\/__admin\/support\/fail\/(\d{3})\/(\d+)$/);
  if (failKnob) { state.fail = { status: Number(failKnob[1]), n: Number(failKnob[2]) }; return ok(state.fail); }
  const delayKnob = pathname.match(/^\/__admin\/support\/delay\/(\d+)$/);
  if (delayKnob) { state.delay = Number(delayKnob[1]); return ok({ delay: state.delay }); }
  if (pathname === '/__admin/support/tickets') return ok(state.tickets);
  return false;
}

/// The ticket body's problems, as the API lists them (`error.data`).
function ticketErrors(body) {
  const errors = [];
  const text = (key, max) => {
    const value = body[key];
    if (typeof value !== 'string' || value.trim().length < 1) errors.push({ key, message: 'must NOT have fewer than 1 characters' });
    else if (value.length > max) errors.push({ key, message: `must NOT have more than ${max} characters` });
  };
  text('subject', 200);
  text('body', 4000);
  const category = CATEGORIES.find((c) => c.key === body.category);
  if (!category) { errors.push({ key: 'category', message: 'must be equal to one of the allowed values' }); return errors; }
  let rule = category;
  if (body.subcategory != null) {
    rule = category.children.find((t) => t.key === body.subcategory);
    if (!rule) { errors.push({ key: 'subcategory', message: `is not a topic of ${category.key}` }); return errors; }
  }
  if (body.orderId != null && !OBJECT_ID.test(String(body.orderId))) errors.push({ key: 'orderId', message: 'must match pattern "^[0-9a-fA-F]{24}$"' });
  if (rule.requireOrder && body.orderId == null) errors.push({ key: 'orderId', message: 'is required for this category' });
  // The live API wants ObjectIds; this mock's catalogue uses readable ids
  // (`p_rice` …), so any non-empty string passes here.
  const products = body.productIds;
  if (products != null && (!Array.isArray(products) || products.some((id) => typeof id !== 'string' || !id))) errors.push({ key: 'productIds', message: 'must be ObjectIds' });
  if (rule.requireProducts && (!Array.isArray(products) || products.length === 0)) errors.push({ key: 'productIds', message: 'is required for this category' });
  return errors;
}

/// [api]: { req, pathname, body, lang, authed, ok, fail, notify }.
function handleSupport(api) {
  const { req, pathname, body, lang, authed, ok, fail, notify } = api;
  if (!pathname.startsWith('/v1/support/')) return false;
  const say = (en, ar) => (lang === 'ar' ? ar : en);
  const tickets = pathname === '/v1/support/tickets' && req.method === 'POST';
  if (pathname !== '/v1/support/categories' && !tickets) return false;
  if (tickets && !authed) {
    fail(401, 'AUTHENTICATION_REQUIRED', say('Sign in to continue', 'سجّل الدخول للمتابعة'));
    return true;
  }
  const reply = () => {
    if (state.fail.n > 0) {
      state.fail.n--;
      const status = state.fail.status;
      return fail(status, FAIL_CODES[status] || 'INTERNAL_ERROR', say('Something went wrong, try again', 'حدث خطأ، حاول مرة أخرى'));
    }
    if (!tickets) return ok({ data: CATEGORIES }, 'DATA_LOADED');
    const errors = ticketErrors(body);
    if (errors.length) return fail(400, 'VALIDATION_ERROR', say('Validation failed', 'فشل التحقق'), errors);
    const now = new Date().toISOString();
    const ticket = {
      _id: oid(), ticketNumber: `T-${1000 + state.tickets.length}`, orderId: body.orderId || null,
      productIds: body.productIds || [], subject: body.subject, category: body.category,
      subcategory: body.subcategory || null, body: body.body, channel: 'in_app', status: 'open',
      priority: 'normal', createdBy: 'customer', createdAt: now, updatedAt: now,
    };
    state.tickets.push(ticket);
    notify({
      type: 'support.ticket_created',
      title: { en: 'We got your message', ar: 'وصلتنا رسالتك' },
      body: { en: `Ticket ${ticket.ticketNumber}: ${ticket.subject}`, ar: `التذكرة ${ticket.ticketNumber}: ${ticket.subject}` },
      data: { ticketNumber: ticket.ticketNumber },
    });
    return ok({ message: say('Ticket created', 'تم إنشاء التذكرة'), ticketId: ticket._id }, 'CREATED');
  };
  if (state.delay > 0) setTimeout(reply, state.delay); else reply();
  return true;
}

module.exports = { handleSupport, handleSupportAdmin };
