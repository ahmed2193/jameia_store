// Envelope-accurate mock of the jm3eia customer API for emulator testing
// (https://docs.jm3eia.store/developers/, https://api.jm3eia.store/docs/json).
//   POST /v1/auth/send-otp {phone}            -> {message, code}   (code echoed = non-prod)
//   POST /v1/auth/verify-otp {phone, code}    -> {customer, accessToken, refreshToken, tokenType, expiresIn}
//   POST /v1/auth/refresh {refreshToken}      -> new pair (old refresh revoked)
//   POST /v1/auth/logout (Bearer)             -> {message}
//   GET  /v1/account/me (Bearer)              -> customer
//   PATCH /v1/account/profile (Bearer)        -> customer (name, email, language, gender, dateOfBirth, householdSize)
//   GET  /v1/notifications?page&limit&status  -> {data, pagination, unreadCount}
//   PATCH /v1/notifications/read-all          -> {updatedCount}
//   PATCH /v1/notifications/:id/read          -> notification
//   GET  /v1/notifications/sse                -> text/event-stream (event: notification)
//   POST /v1/push/register {token, platform}  -> {message}
//   GET  /v1/init                             -> minimal store snapshot
// Test knobs:
//   ?expire=1  on /v1/account/me   -> always 401 TOKEN_EXPIRED (forces refresh path)
//   POST /__admin/expire-access    -> current access tokens become invalid (next call 401 -> refresh works)
//   POST /__admin/revoke-refresh   -> refresh tokens revoked (refresh -> 401 INVALID_TOKEN -> app must go to login)
//   POST /__admin/rate-limit/:n    -> next n requests answer 429 RATE_LIMITED (Retry-After: 1)
//   POST /__admin/expires-in/:sec  -> pairs issued from now on carry expiresIn = sec (pre-flight refresh demo)
//   POST /__admin/notify {type,title,body,orderId} -> creates an unread notification and pushes it over SSE
//   GET  /__admin/log              -> request log (method, path, headers of interest)
const http = require('http');
const url = require('url');
const crypto = require('crypto');
const PORT = Number(process.env.MOCK_API_PORT || 5055);
const OTP = process.env.OTP || '1234';

const state = { access: new Set(), refresh: new Set(), rateLimit: 0, expiresIn: 900, log: [], sse: new Set() };
const customer = {
  _id: '507f1f77bcf86cd799439011', name: 'Ahmed', phone: '+96512345678', email: 'ahmed@jm3eia.com',
  dateOfBirth: null, gender: 'male', householdSize: null, status: 'active', language: 'en',
  wallet: 1250, loyaltyPoints: 320, pro: { active: false, expiresAt: null, subscriptionId: null },
  addresses: [], pushTokens: [], marketingPush: true, lastLoginAt: null, lastLoginIp: null,
  createdAt: '2026-01-01T00:00:00.000Z', updatedAt: '2026-01-01T00:00:00.000Z',
};
const oid = () => crypto.randomBytes(12).toString('hex');
const TYPES = ['order.placed', 'order.confirmed', 'order.out_for_delivery', 'order.delivered', 'points.earned', 'wallet.credited', 'coupon.received', 'offer.expiring', 'support.replied', 'campaign.message', 'account.welcome'];
const notifications = [];
for (let i = 0; i < 27; i++) {
  const type = TYPES[i % TYPES.length];
  const createdAt = new Date(Date.now() - i * 3600e3 * 5).toISOString();
  notifications.push({
    _id: oid(), recipientType: 'customer', recipientId: customer._id, type,
    status: i < 4 ? 'unread' : 'read',
    title: { en: `${type.replace('.', ' ')} #${27 - i}`, ar: `إشعار ${27 - i}` },
    body: { en: `Mock body for ${type} (${27 - i})`, ar: `نص تجريبي للإشعار ${27 - i}` },
    data: type.startsWith('order') ? { orderId: oid(), orderNumber: `JM-${1000 + i}` } : type.startsWith('support') ? { ticketNumber: `T-${100 + i}` } : {},
    readAt: i < 4 ? null : createdAt, createdAt, updatedAt: createdAt,
  });
}

const ok = (res, results, statusMessage = 'SUCCESS') =>
  send(res, 200, { success: true, statusCode: 200, statusMessage, results, error: null });
const fail = (res, status, statusMessage, message, data = [], headers = {}) =>
  send(res, status, { success: false, statusCode: status, statusMessage, results: null, error: { message, data } }, headers);
function send(res, status, body, headers = {}) {
  res.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8', ...headers });
  res.end(JSON.stringify(body));
}
const token = (p) => p + '_' + crypto.randomBytes(8).toString('hex');
function issuePair() {
  const accessToken = token('acc'), refreshToken = token('ref');
  state.access.add(accessToken); state.refresh.add(refreshToken);
  return { accessToken, refreshToken, tokenType: 'Bearer', expiresIn: state.expiresIn };
}
const bearer = (req) => (req.headers.authorization || '').replace(/^Bearer /, '') || null;
const authed = (req) => state.access.has(bearer(req));
const localized = (req, en, ar) => (req.headers['accept-language'] || 'en').startsWith('ar') ? ar : en;
const unread = () => notifications.filter((n) => n.status === 'unread').length;
function pushSse(notification) {
  const frame = `event: notification\ndata: ${JSON.stringify(notification)}\n\n`;
  for (const res of state.sse) res.write(frame);
}

http.createServer((req, res) => {
  let raw = '';
  req.on('data', (c) => (raw += c));
  req.on('end', () => {
    const { pathname, query } = url.parse(req.url, true);
    let body = {};
    try { body = raw ? JSON.parse(raw) : {}; } catch { return fail(res, 400, 'VALIDATION_ERROR', 'Bad JSON'); }
    state.log.push({ t: new Date().toISOString(), m: req.method, p: pathname, auth: bearer(req), lang: req.headers['accept-language'], cart: req.headers['x-cart-token'], guest: req.headers['x-assistant-guest'], body });
    console.log(`${req.method} ${pathname} auth=${bearer(req) ? bearer(req).slice(0, 12) : '-'} lang=${req.headers['accept-language'] || '-'} guest=${(req.headers['x-assistant-guest'] || '-').slice(0, 8)} body=${raw}`);

    // admin knobs
    if (pathname === '/__admin/expire-access') { state.access.clear(); return ok(res, { cleared: true }); }
    if (pathname === '/__admin/revoke-refresh') { state.refresh.clear(); return ok(res, { revoked: true }); }
    if (pathname.startsWith('/__admin/rate-limit/')) { state.rateLimit = Number(pathname.split('/').pop()); return ok(res, { rateLimit: state.rateLimit }); }
    if (pathname.startsWith('/__admin/expires-in/')) { state.expiresIn = Number(pathname.split('/').pop()); return ok(res, { expiresIn: state.expiresIn }); }
    if (pathname === '/__admin/notify') {
      const type = body.type || 'campaign.message';
      const now = new Date().toISOString();
      const n = { _id: oid(), recipientType: 'customer', recipientId: customer._id, type, status: 'unread',
        title: { en: body.title || 'Live notification', ar: body.titleAr || 'إشعار مباشر' },
        body: { en: body.body || 'Pushed over SSE', ar: body.bodyAr || 'تم الإرسال عبر SSE' },
        data: body.orderId ? { orderId: body.orderId, orderNumber: body.orderNumber || 'JM-LIVE' } : {}, readAt: null, createdAt: now, updatedAt: now };
      notifications.unshift(n); pushSse(n);
      return ok(res, { pushed: n._id, clients: state.sse.size });
    }
    if (pathname === '/__admin/log') return ok(res, state.log);
    if (state.rateLimit > 0) { state.rateLimit--; return fail(res, 429, 'RATE_LIMITED', localized(req, 'Too many requests', 'طلبات كثيرة جدًا'), [], { 'Retry-After': '1' }); }

    // auth
    if (req.method === 'POST' && pathname === '/v1/auth/send-otp') {
      if (typeof body.phone !== 'string' || body.phone.length < 4) return fail(res, 400, 'VALIDATION_ERROR', localized(req, 'Validation failed', 'فشل التحقق'), [{ key: 'phone', message: 'must NOT have fewer than 4 characters' }]);
      return ok(res, { message: localized(req, `Code sent to ${body.phone}`, `تم إرسال الرمز إلى ${body.phone}`), code: OTP });
    }
    if (req.method === 'POST' && pathname === '/v1/auth/verify-otp') {
      if (body.code !== OTP) return fail(res, 400, 'INVALID_CREDENTIALS', localized(req, 'Wrong code, try again', 'رمز غير صحيح، حاول مرة أخرى'));
      customer.phone = body.phone;
      return ok(res, { customer, ...issuePair() });
    }
    if (req.method === 'POST' && pathname === '/v1/auth/refresh') {
      if (!state.refresh.has(body.refreshToken)) return fail(res, 401, 'INVALID_TOKEN', localized(req, 'Your session has expired. Please sign in again', 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى'));
      state.refresh.delete(body.refreshToken);
      return ok(res, issuePair());
    }
    if (req.method === 'POST' && pathname === '/v1/auth/logout') {
      if (!authed(req)) return fail(res, 401, 'AUTHENTICATION_REQUIRED', localized(req, 'Sign in to continue', 'سجّل الدخول للمتابعة'));
      state.refresh.clear(); state.access.clear();
      return ok(res, { message: 'Logged out' });
    }

    // account
    if (pathname === '/v1/account/me' && req.method === 'GET') {
      if (query.expire === '1' || !authed(req)) return fail(res, 401, authed(req) ? 'TOKEN_EXPIRED' : 'AUTHENTICATION_REQUIRED', localized(req, 'Sign in to continue', 'سجّل الدخول للمتابعة'));
      return ok(res, customer, 'DATA_LOADED');
    }
    if (pathname === '/v1/account/profile' && req.method === 'PATCH') {
      if (!authed(req)) return fail(res, 401, 'AUTHENTICATION_REQUIRED', localized(req, 'Sign in to continue', 'سجّل الدخول للمتابعة'));
      if ('name' in body && (typeof body.name !== 'string' || !body.name.trim())) return fail(res, 400, 'VALIDATION_ERROR', localized(req, 'Validation failed', 'فشل التحقق'), [{ key: 'name', message: 'must NOT have fewer than 1 characters' }]);
      if ('language' in body && !['en', 'ar'].includes(body.language)) return fail(res, 400, 'VALIDATION_ERROR', localized(req, 'Validation failed', 'فشل التحقق'), [{ key: 'language', message: 'must be en or ar' }]);
      for (const k of ['name', 'email', 'language', 'dateOfBirth', 'gender', 'householdSize']) if (k in body) customer[k] = body[k];
      customer.updatedAt = new Date().toISOString();
      return ok(res, customer, 'UPDATED');
    }

    // notifications
    if (pathname.startsWith('/v1/notifications') || pathname === '/v1/push/register') {
      if (!authed(req)) return fail(res, 401, 'AUTHENTICATION_REQUIRED', localized(req, 'Sign in to continue', 'سجّل الدخول للمتابعة'));
    }
    if (pathname === '/v1/notifications/sse' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache', Connection: 'keep-alive' });
      res.write(': connected\n\n');
      state.sse.add(res);
      const ping = setInterval(() => res.write(': ping\n\n'), 15000);
      res.on('close', () => { clearInterval(ping); state.sse.delete(res); });
      return;
    }
    if (pathname === '/v1/notifications' && req.method === 'GET') {
      const page = Math.max(1, Number(query.page || 1)), limit = Math.min(100, Math.max(1, Number(query.limit || 20)));
      const list = query.status ? notifications.filter((n) => n.status === query.status) : notifications;
      const data = list.slice((page - 1) * limit, page * limit);
      return ok(res, { data, pagination: { total: list.length, page, limit, hasMore: page * limit < list.length }, unreadCount: unread() }, 'DATA_LOADED');
    }
    if (pathname === '/v1/notifications/read-all' && req.method === 'PATCH') {
      let updatedCount = 0;
      for (const n of notifications) if (n.status === 'unread') { n.status = 'read'; n.readAt = new Date().toISOString(); updatedCount++; }
      return ok(res, { updatedCount }, 'UPDATED');
    }
    const readMatch = pathname.match(/^\/v1\/notifications\/([0-9a-f]{24})\/read$/);
    if (readMatch && req.method === 'PATCH') {
      const n = notifications.find((x) => x._id === readMatch[1]);
      if (!n) return fail(res, 404, 'RESOURCE_NOT_FOUND', 'Not found');
      n.status = 'read'; n.readAt = new Date().toISOString();
      return ok(res, n, 'UPDATED');
    }
    if (pathname === '/v1/push/register' && req.method === 'POST') {
      if (typeof body.token !== 'string' || body.token.length < 10 || !['ios', 'android'].includes(body.platform)) return fail(res, 400, 'VALIDATION_ERROR', 'Validation failed', [{ key: 'token', message: 'invalid' }]);
      if (!customer.pushTokens.includes(body.token)) customer.pushTokens.push(body.token);
      return ok(res, { message: 'Registered' });
    }

    if (req.method === 'GET' && pathname === '/v1/init') {
      return ok(res, { store: { name: 'Jm3eia', tagline: 'mock', defaultLocale: 'en', assistant: { enabled: true, allowGuests: true } }, user: authed(req) ? customer : null, cartToken: 'cart_' + crypto.randomBytes(4).toString('hex') }, 'DATA_LOADED');
    }
    return fail(res, 404, 'RESOURCE_NOT_FOUND', 'Not found');
  });
}).listen(PORT, '0.0.0.0', () => console.log(`mock jm3eia api on http://0.0.0.0:${PORT} (OTP=${OTP})`));
