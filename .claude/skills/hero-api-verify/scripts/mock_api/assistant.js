// Hero Assistant routes for the mock Hero API (docs: /developers/assistant.html,
// contract notes L1–L20 in docs/prompts/assistant_chat_prompt.md). Plugged into
// server.js by ONE dispatch line; returns true when it owned the request.
//   GET  /v1/assistant/conversations?page&limit&search -> {data, pagination}  (search ignored — live L11)
//   GET  /v1/assistant/conversations/:id               -> {conversation, messages}
//   POST /v1/assistant/messages {message, conversationId?} -> text/event-stream:
//        : connected, message_start, user_message, (tool_start / tool_end / block / text_delta)*, message_end | error
//   POST /v1/assistant/actions/:actionId/confirm {}    -> {message, blocks:[cart_summary, cart_action(confirmed)]}  (2nd confirm -> 404)
//   POST /v1/assistant/conversations/:id/handoff {}    -> {ticketId, ticketNumber, message}  (idempotent; NEVER call live)
//   POST /v1/assistant/messages/:id/feedback {feedback: up|down|null} -> {message}
// Identity (like live): a valid Bearer -> the customer; an unknown Bearer is IGNORED (N2);
// else X-Assistant-Guest -> that guest; neither -> lists are empty, sends make orphans (L10).
// Side effects (the request goes on to server.js): a good POST /v1/auth/verify-otp moves the
// guest's threads to the customer; GET /v1/init gets store.assistant + featureFlags patched.
//
// Scripted replies by keyword (EN / AR), every block kind:
//   butter eggs milk rice apple bread water chicken (زبدة بيض حليب أرز تفاح خبز ماء دجاج) -> one
//   search_products + `products` block per word (N8) · "add 2 butter" / "أضف ٢ زبدة" -> products +
//   cart_action · details / تفاصيل -> product_detail · my cart / سلتي -> cart_summary ·
//   track / تتبع -> order_status · orders / طلباتي -> order blocks · offers coupon / عروض كوبون ->
//   offers + WELCOME · recipe breakfast / وصفة فطور -> recipe · faq refund / أسئلة استرجاع -> faq ·
//   categories / أقسام -> categories · brands / ماركات -> brands · slots / مواعيد -> delivery_slots ·
//   fee / رسوم -> delivery_info · area / منطقة -> EMPTY delivery_info (L13) · branch / فرع ->
//   locations · human / موظف -> text offering a person · escalate / تصعيد -> the ASSISTANT opens a
//   ticket (handoff block, N6) · error / خطأ -> tool ok:false + in-band error block · future ->
//   unknown `future_card` + products · markdown -> headings/lists/bold · long / طويل -> ~7,900
//   chars · everything / كل شيء -> every kind · anything else -> text + chips.
//
// Knobs (any method):
//   GET  /__admin/assistant                     -> state dump (knobs, conversations, actions)
//   POST /__admin/assistant/reset               -> no conversations / actions / tickets, knobs off
//   POST /__admin/assistant/fail-persist/:n     -> next n turns stream blocks + text, then error
//                                                  {INTERNAL_ERROR,"Document failed validation"}; nothing saved (L7)
//   POST /__admin/assistant/error-frame/:n[?code=X] -> next n turns: half the text, then error {code}
//   POST /__admin/assistant/drop-mid-stream/:n  -> next n turns: socket destroyed mid-text (no terminal event);
//                                                  the reply is still saved (reload shows it)
//   POST /__admin/assistant/slow/:ms            -> extra wait before the first tool / word (heartbeats keep it alive)
//   POST /__admin/assistant/stall/:ms           -> same wait with NO heartbeat (trips the app's 60 s idle watchdog)
//   POST /__admin/assistant/closed/:n           -> next n sends find their thread closed: message_start carries a NEW id
//   POST /__admin/assistant/disabled/:status    -> every assistant route answers :status (0 = off); init enabled:false
//   POST /__admin/assistant/guests-off/:0|1     -> signed-out callers get 401 AUTHENTICATION_REQUIRED; init allowGuests
//   POST /__admin/assistant/flag/:0|1           -> init store.featureFlags.assistant
//   POST /__admin/assistant/rate-limit/:n       -> next n assistant requests 429 RATE_LIMITED (Retry-After: 1)
//   POST /__admin/assistant/validation/:n       -> next n sends 400 VALIDATION_ERROR (before the stream)
//   POST /__admin/assistant/fail/:route/:status/:n -> route = list|detail|confirm|feedback|handoff
//   POST /__admin/assistant/delay/:ms           -> JSON routes wait :ms (double taps, in-flight UI)
//   POST /__admin/assistant/expire-actions      -> every pending proposal can no longer be confirmed (404)
//   POST /__admin/assistant/strict-auth/:0|1    -> an unknown Bearer gets 401 TOKEN_EXPIRED instead of being ignored
//   POST /__admin/assistant/seed/:n[?owner=customer|<32-hex guest>] -> n finished conversations over the last weeks
const crypto = require('crypto');
const catalog = require('./catalog.js');
const commerce = require('./commerce.js');
const { handleCommerce } = require('./routes_commerce.js');
const FIXTURES = require('./catalog_fixtures.json');

const DELTA_MS = 10, FIRST_TOKEN_MS = 700, TOOL_MS = 4, HEARTBEAT_MS = 15000;
const MAX_MESSAGES = 40, PREVIEW_CHARS = 160, MAX_PROMPT = 2000, TITLE_CHARS = 120;
const HEX24 = /^[0-9a-fA-F]{24}$/;
const oid = () => crypto.randomBytes(12).toString('hex');
const callId = () => 'call_' + crypto.randomBytes(18).toString('base64').replace(/[^A-Za-z0-9]/g, '').slice(0, 24);
const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
const FAIL_CODES = { 400: 'VALIDATION_ERROR', 401: 'AUTHENTICATION_REQUIRED', 403: 'FORBIDDEN', 404: 'RESOURCE_NOT_FOUND', 409: 'RESOURCE_EXISTS', 500: 'INTERNAL_ERROR', 503: 'SERVICE_UNAVAILABLE' };

const freshKnobs = () => ({
  failPersist: 0, errorFrame: 0, errorCode: 'INTERNAL_ERROR', drop: 0, slow: 0, stall: 0, closed: 0,
  disabled: 0, guestsOff: false, featureFlag: true, rateLimit: 0, validation: 0, delay: 0,
  strictAuth: false, fail: {},
});
const state = {
  conversations: new Map(), // id -> { conv, owner, messages: [] }
  actions: new Map(), // actionId -> { owner, convId, messageId, block, status }
  tickets: 0,
  knobs: freshKnobs(),
};

const t = (lang, en, ar) => (lang === 'ar' ? ar : en);
const now = () => new Date().toISOString();
const codePoints = (text) => [...text].length;
const arabicDigits = (text) => text.replace(/[٠-٩]/g, (d) => String('٠١٢٣٤٥٦٧٨٩'.indexOf(d)));

// --- catalogue rows in block shape -------------------------------------------------------
const PRODUCT_WORDS = [
  { slug: 'lurpak-butter-200g', en: /butter/i, ar: /زبد/ },
  { slug: 'fresh-eggs-30', en: /\beggs?\b/i, ar: /بيض/ },
  { slug: 'kdd-full-cream-milk', en: /\bmilk\b/i, ar: /حليب/ },
  { slug: 'basmati-rice-5kg', en: /\brice\b/i, ar: /أرز|ارز|رز/ },
  { slug: 'red-apples', en: /\bapples?\b/i, ar: /تفاح/ },
  { slug: 'arabic-bread-6-pack', en: /\bbread\b/i, ar: /خبز/ },
  { slug: 'mai-dubai-water-1-5l', en: /\bwater\b/i, ar: /ماء|مياه/ },
  { slug: 'almarai-chicken-900g', en: /chicken/i, ar: /دجاج/ },
  { slug: 'breakfast-bundle', en: /bundle/i, ar: /باقة/ },
];
const productRow = (lang, slug) => {
  const row = catalog.productsOf(lang).find((p) => p.slug === slug);
  return row ? { ...row, stock: commerce.product(row._id) ? commerce.capOf(row._id) : row.stock } : null;
};
const listOf = (lang, key) => ((FIXTURES[`${lang}/${key}`] || {}).data || []);

function mentionedProducts(message) {
  return PRODUCT_WORDS.filter((w) => w.en.test(message) || w.ar.test(message)).map((w) => w.slug);
}

// --- identity ------------------------------------------------------------------------------
function identity(api) {
  if (api.authed) return { owner: 'customer' };
  const { req, lang } = api;
  if (state.knobs.strictAuth && req.headers.authorization) {
    return { status: 401, code: 'TOKEN_EXPIRED', message: t(lang, 'Your session has expired', 'انتهت صلاحية الجلسة') };
  }
  if (state.knobs.guestsOff) {
    return { status: 401, code: 'AUTHENTICATION_REQUIRED', message: t(lang, 'Sign in to continue', 'سجّل الدخول للمتابعة') };
  }
  const guest = req.headers['x-assistant-guest'];
  return { owner: guest ? 'guest:' + guest : null };
}

// --- conversations -------------------------------------------------------------------------
function newConversation(owner, lang, title) {
  const at = now();
  const conv = {
    _id: oid(), title: title.slice(0, TITLE_CHARS), language: lang, status: 'active', supportTicketId: null,
    messageCount: 0, lastMessageAt: at, lastMessagePreview: '', usage: { promptTokens: 0, completionTokens: 0 },
    createdAt: at, updatedAt: at,
  };
  const entry = { conv, owner, messages: [] };
  state.conversations.set(conv._id, entry);
  return entry;
}
const owned = (id, owner) => {
  const entry = state.conversations.get(id);
  return entry && owner && entry.owner === owner ? entry : null;
};
const preview = (text) => {
  const flat = text.replace(/\s+/g, ' ').trim();
  return flat.length > PREVIEW_CHARS ? flat.slice(0, PREVIEW_CHARS - 1) + '…' : flat;
};
function message(convId, role, content, blocks, createdAt = now()) {
  return { _id: oid(), conversationId: convId, role, content, blocks, feedback: null, createdAt, updatedAt: createdAt };
}

// --- scripts -------------------------------------------------------------------------------
// A plan: { tools: [{ name, ok, blocks }], text, suggestions, handoff }
const chips = (lang, pairs) => pairs.map(([en, enPrompt, ar, arPrompt]) => ({ label: t(lang, en, ar), prompt: t(lang, enPrompt, arPrompt) }));
const CHIPS = {
  deals: ['Best deals', 'Show me the best deals today', 'أفضل العروض', 'اعرض لي أفضل عروض اليوم'],
  breakfast: ['Breakfast idea', 'Suggest a breakfast recipe', 'فكرة فطور', 'اقترح وصفة فطور'],
  cart: ['My cart', 'What is in my cart?', 'سلتي', 'ماذا يوجد في سلتي؟'],
  addButter: ['Add 2 butter', 'Add 2 butter to my cart', 'أضف ٢ زبدة', 'أضف ٢ زبدة إلى السلة'],
  slots: ['Delivery times', 'What delivery slots are available?', 'مواعيد التوصيل', 'ما هي مواعيد التوصيل المتاحة؟'],
  track: ['Track my order', 'Track my order', 'تتبع طلبي', 'تتبع طلبي'],
  human: ['Talk to a person', 'I want to talk to a human agent', 'تحدث مع موظف', 'أريد التحدث مع موظف'],
  eggs: ['Eggs too', 'Show me eggs', 'بيض أيضاً', 'اعرض لي البيض'],
};
const pickChips = (lang, ...keys) => chips(lang, keys.map((k) => CHIPS[k]));

function productsTool(lang, slug) {
  const row = productRow(lang, slug);
  return { name: 'search_products', ok: true, blocks: row ? [{ kind: 'products', products: [row] }] : [] };
}

function orderBlockOf(order) {
  return {
    _id: order._id, orderNumber: order.orderNumber, status: order.status, total: order.total, createdAt: order.createdAt,
    itemCount: order.lines.reduce((sum, l) => sum + l.quantity, 0),
    thumbnails: order.lines.slice(0, 4).map((l) => l.product.image || null),
  };
}
function seedOrder(lang, customer) {
  if (commerce.state.orders.length) return;
  const cart = { cartToken: 'assistant_seed', lines: [], coupon: null, loyaltyPoints: 0, express: false, mode: 'delivery', branchId: 'b_salmiya', addressId: null, slot: null };
  for (const [slug, quantity] of [['lurpak-butter-200g', 2], ['fresh-eggs-30', 1], ['red-apples', 3], ['arabic-bread-6-pack', 1], ['basmati-rice-5kg', 1]]) {
    const row = productRow('en', slug);
    if (row) cart.lines.push({ key: 'ln_' + oid().slice(0, 8), productId: row._id, variantId: null, quantity });
  }
  commerce.placeOrder(cart, { paymentMethod: 'cod' }, lang, customer);
}

const FAQ = (lang) => [
  { id: 'delivery-areas', question: t(lang, 'Where do you deliver?', 'أين توصلون؟'), answer: t(lang, 'We deliver across Kuwait; the fee depends on your area.', 'نوصل إلى جميع مناطق الكويت، والرسوم حسب منطقتك.') },
  { id: 'refunds', question: t(lang, 'How do refunds work?', 'كيف يتم الاسترجاع؟'), answer: t(lang, 'Refunds go back to your wallet within 24 hours of approval.', 'يعود المبلغ إلى محفظتك خلال ٢٤ ساعة من الموافقة.') },
  { id: 'payment', question: t(lang, 'How can I pay?', 'كيف يمكنني الدفع؟'), answer: t(lang, 'Cash on delivery, card on delivery or your Hero wallet.', 'نقداً أو بالبطاقة عند الاستلام أو من محفظة هيرو.') },
];
const locationsOf = (lang) => commerce.BRANCHES.map((b) => ({ label: b.name[lang] || b.name.en, address: b.address[lang] || b.address.en, phone: b.phone, lat: b.lat, lng: b.lng }));
function recipeBlock(lang, slug) {
  const row = listOf(lang, 'recipes').find((r) => r.slug === slug);
  if (!row) return null;
  const { excerpt, ...recipe } = row;
  const detail = FIXTURES[`${lang}/recipes/${slug}`];
  return { kind: 'recipe', recipe, servings: recipe.servings, ingredientCount: detail && detail.ingredients ? detail.ingredients.length : 0 };
}
const LONG_EN = 'Here is a complete guide to stocking a Kuwaiti pantry for a busy month. ';
const LONG_AR = 'إليك دليلاً كاملاً لتجهيز مخزن البيت لشهر مزدحم. ';

function plan(api, text, owner, entry) {
  const { lang } = api;
  const lower = text.toLowerCase();
  const has = (en, ar) => en.test(lower) || ar.test(text);
  const slugs = mentionedProducts(text);
  const signedIn = owner === 'customer';

  if (has(/\beverything\b|\bdemo\b/, /كل شيء/)) return everythingPlan(api, owner);

  if (has(/\badd\b|\bput\b/, /أضف|اضف|ضع/) && slugs.length) {
    const quantity = Math.min(50, Math.max(1, Number((arabicDigits(text).match(/\d+/) || ['1'])[0])));
    const rows = slugs.map((slug) => productRow(lang, slug)).filter(Boolean);
    const items = rows.map((row) => ({ productId: row._id, variantId: null, quantity, product: row }));
    const names = rows.map((row) => row.name).join(t(lang, ' and ', ' و'));
    return {
      tools: [...slugs.map((slug) => productsTool(lang, slug)), {
        name: 'add_to_cart', ok: true,
        blocks: [{ kind: 'cart_action', actionId: crypto.randomBytes(12).toString('hex'), items, status: 'pending',
          estimatedTotal: rows.reduce((sum, row) => sum + row.price * quantity, 0) }],
      }],
      text: t(lang, `I've prepared ${quantity} × ${names} for your cart. Nothing is added yet — tap **Add to cart** to confirm.`,
        `جهزت لك ${quantity} × ${names} للسلة. لم تتم الإضافة بعد — اضغط **أضف إلى السلة** للتأكيد.`),
      suggestions: pickChips(lang, 'cart', 'slots', 'breakfast'),
    };
  }
  if (has(/\babout\b|\bdetails?\b/, /تفاصيل|معلومات/) && slugs.length) {
    const row = productRow(lang, slugs[0]);
    return {
      tools: [{ name: 'get_product', ok: true, blocks: row ? [{ kind: 'product_detail', product: row }] : [] }],
      text: t(lang, `**${row.name}** is one of our best sellers. It is in stock and ready for delivery today.`,
        `**${row.name}** من أكثر المنتجات مبيعاً، ومتوفر للتوصيل اليوم.`),
      suggestions: pickChips(lang, 'addButter', 'deals'),
    };
  }
  if (has(/my cart|\bbasket\b/, /سلتي|السلة/)) {
    const cart = commerce.cartPayload(commerce.cartOf(api.req, api.authed), lang);
    return {
      tools: [{ name: 'get_cart', ok: true, blocks: [{ kind: 'cart_summary', cart }] }],
      text: cart.itemCount
        ? t(lang, `You have ${cart.itemCount} items in your cart.`, `لديك ${cart.itemCount} منتجات في سلتك.`)
        : t(lang, 'Your cart is empty. Want some ideas?', 'سلتك فارغة. هل تريد بعض الاقتراحات؟'),
      suggestions: pickChips(lang, 'deals', 'addButter'),
    };
  }
  if (has(/\btrack\b|where is my order/, /تتبع|وين طلبي|أين طلبي/)) {
    if (!signedIn) return textPlan(lang, t(lang, 'Please sign in so I can find your orders.', 'يرجى تسجيل الدخول حتى أجد طلباتك.'), 'deals');
    seedOrder(lang, api.customer);
    const order = commerce.state.orders[0];
    return {
      tools: [{ name: 'track_order', ok: true, blocks: [{ kind: 'order_status', order: orderBlockOf(order) }] }],
      text: t(lang, `Your order **${order.orderNumber}** is currently *${order.status.replace(/_/g, ' ')}*.`, `طلبك **${order.orderNumber}** حالته الآن: ${order.status}.`),
      suggestions: pickChips(lang, 'human', 'deals'),
    };
  }
  if (has(/\borders?\b/, /طلباتي|طلبات/)) {
    if (!signedIn) return textPlan(lang, t(lang, 'Please sign in so I can find your orders.', 'يرجى تسجيل الدخول حتى أجد طلباتك.'), 'deals');
    seedOrder(lang, api.customer);
    const orders = commerce.state.orders.slice(0, 3);
    return {
      tools: [{ name: 'list_orders', ok: true, blocks: orders.map((o) => ({ kind: 'order', order: orderBlockOf(o) })) }],
      text: t(lang, `Here are your latest ${orders.length} orders.`, `هذه آخر ${orders.length} طلبات لك.`),
      suggestions: pickChips(lang, 'track', 'deals'),
    };
  }
  if (has(/\boffers?\b|\bcoupons?\b|\bdeals?\b/, /عرض|عروض|كوبون|خصم/)) {
    return {
      tools: [{ name: 'list_offers', ok: true, blocks: [{ kind: 'offers', offers: listOf(lang, 'offers'), couponCode: 'WELCOME' }] }],
      text: t(lang, 'Current offers include:\n- Free delivery over 5 KWD\n- 10% off over 15 KWD\n\nUse code **WELCOME** at checkout.',
        'العروض الحالية:\n- توصيل مجاني فوق ٥ د.ك\n- خصم ١٠٪ فوق ١٥ د.ك\n\nاستخدم الكود **WELCOME** عند الدفع.'),
      suggestions: pickChips(lang, 'breakfast', 'addButter'),
    };
  }
  if (has(/\brecipes?\b|\bbreakfast\b|\bcook\b/, /وصف|فطور|طبخ/)) {
    const block = recipeBlock(lang, 'kuwaiti-egg-breakfast');
    return {
      tools: [{ name: 'search_recipes', ok: true, blocks: block ? [block] : [] }],
      text: t(lang, 'For breakfast, try the **Kuwaiti Egg & Bread Breakfast** — quick, vegetarian and ready in 15 minutes.',
        'للفطور جرّب **فطور البيض والخبز الكويتي** — سريع ونباتي وجاهز خلال ١٥ دقيقة.'),
      suggestions: pickChips(lang, 'eggs', 'deals'),
    };
  }
  if (has(/\bfaq\b|\brefunds?\b|\breturns?\b|\bpayment\b|\bpay\b/, /أسئلة|استرجاع|ارجاع|دفع/)) {
    return {
      tools: [{ name: 'search_faq', ok: true, blocks: [{ kind: 'faq', items: FAQ(lang) }] }],
      text: t(lang, 'Here are answers to the most common questions.', 'إليك إجابات أكثر الأسئلة شيوعاً.'),
      suggestions: pickChips(lang, 'human', 'slots'),
    };
  }
  if (has(/categor/, /أقسام|قسم|فئات/)) {
    return {
      tools: [{ name: 'list_categories', ok: true, blocks: [{ kind: 'categories', categories: listOf(lang, 'categories').filter((c) => !c.parentId) }] }],
      text: t(lang, 'Here are our main sections.', 'هذه أقسامنا الرئيسية.'),
      suggestions: pickChips(lang, 'deals', 'breakfast'),
    };
  }
  if (has(/\bbrands?\b/, /ماركة|ماركات|علامة/)) {
    return {
      tools: [{ name: 'list_brands', ok: true, blocks: [{ kind: 'brands', brands: listOf(lang, 'brands') }] }],
      text: t(lang, 'These are the brands we carry.', 'هذه العلامات التجارية المتوفرة لدينا.'),
      suggestions: pickChips(lang, 'deals', 'addButter'),
    };
  }
  if (has(/\bslots?\b|\bwhen\b|delivery times?/, /مواعيد|موعد|متى/)) {
    return {
      tools: [{ name: 'list_delivery_slots', ok: true, blocks: [{ kind: 'delivery_slots', days: commerce.slotDays(lang) }] }],
      text: t(lang, 'These delivery times are open. You choose one at checkout.', 'هذه مواعيد التوصيل المتاحة، وتختار منها عند الدفع.'),
      suggestions: pickChips(lang, 'cart', 'deals'),
    };
  }
  if (has(/\barea\b/, /منطقة|منطقتي/)) {
    // L13 replay: the slots tool fails, the delivery check answers an EMPTY card.
    return {
      tools: [{ name: 'list_delivery_slots', ok: false, blocks: [] }, { name: 'check_delivery', ok: true, blocks: [{ kind: 'delivery_info' }] }],
      text: t(lang, 'Please select a delivery area or pickup branch first to see available delivery slots.', 'يرجى اختيار منطقة التوصيل أو فرع الاستلام أولاً لعرض المواعيد المتاحة.'),
      suggestions: pickChips(lang, 'slots'),
    };
  }
  if (has(/\bfees?\b|delivery cost|\bcost\b/, /رسوم|تكلفة/)) {
    return {
      tools: [{ name: 'check_delivery', ok: true, blocks: [{ kind: 'delivery_info', areaName: t(lang, 'Salmiya', 'السالمية'), zoneName: t(lang, 'Zone 1', 'المنطقة ١'), fee: 500, etaMinutes: 45 }] }],
      text: t(lang, 'Delivery to Salmiya costs 0.500 KWD and takes about 45 minutes.', 'التوصيل إلى السالمية بـ ٠٫٥٠٠ د.ك ويستغرق حوالي ٤٥ دقيقة.'),
      suggestions: pickChips(lang, 'slots', 'cart'),
    };
  }
  if (has(/\bbranch(es)?\b|\blocations?\b|\bstores?\b/, /فرع|فروع|موقع/)) {
    return {
      tools: [{ name: 'list_branches', ok: true, blocks: [{ kind: 'locations', items: locationsOf(lang) }] }],
      text: t(lang, 'Here are our branches. Tap one to open it in maps.', 'هذه فروعنا. اضغط على أي فرع لفتحه في الخرائط.'),
      suggestions: pickChips(lang, 'slots'),
    };
  }
  if (has(/\bescalate\b/, /تصعيد/)) {
    // N6: the assistant opens the ticket itself.
    const ticket = openTicket(entry);
    return {
      tools: [{ name: 'handoff_to_human', ok: true, blocks: [{ kind: 'handoff', ticketId: ticket.ticketId, ticketNumber: ticket.ticketNumber }] }],
      text: t(lang, `I've passed this to our support team (ticket **${ticket.ticketNumber}**). A person will reply here.`, `حوّلت طلبك إلى فريق الدعم (تذكرة **${ticket.ticketNumber}**). سيرد عليك موظف هنا.`),
      suggestions: [],
      handoff: ticket,
    };
  }
  if (has(/\bhuman\b|\bagent\b|\bperson\b|\bsupport\b/, /موظف|شخص|دعم/)) {
    return textPlan(lang, t(lang, 'I can connect you with our support team. Use **Talk to a person** from the menu and a member of the team will reply here.',
      'يمكنني تحويلك إلى فريق الدعم. اختر **تحدث مع موظف** من القائمة وسيرد عليك أحد أعضاء الفريق هنا.'), 'deals');
  }
  if (has(/\berror\b|\bfail\b/, /خطأ|فشل/)) {
    return {
      tools: [{ name: 'search_products', ok: false, blocks: [{ kind: 'error', code: 'TOOL_FAILED', message: t(lang, 'Product search is unavailable right now.', 'البحث عن المنتجات غير متاح حالياً.') }] }],
      text: t(lang, 'Sorry, I could not search the catalogue just now. Please try again in a moment.', 'عذراً، تعذر البحث في المنتجات الآن. حاول مرة أخرى بعد قليل.'),
      suggestions: pickChips(lang, 'deals'),
    };
  }
  if (has(/\bfuture\b|\bunknown\b/, /مستقبل/)) {
    return {
      tools: [{ name: 'search_products', ok: true, blocks: [{ kind: 'future_card', title: 'A card this app does not know', items: [1, 2, 3] }, { kind: 'products', products: [productRow(lang, 'red-apples')] }] }],
      text: t(lang, 'Here is something new, and some fresh apples.', 'إليك شيئاً جديداً، وبعض التفاح الطازج.'),
      suggestions: pickChips(lang, 'deals'),
    };
  }
  if (has(/\bmarkdown\b/, /تنسيق/)) {
    return textPlan(lang, t(lang,
      '## Weekly shop\nA **balanced** basket for two:\n\n- Fresh eggs\n- Arabic bread\n  (the 6 pack)\n- **Lurpak** butter\n\n1. Start with dairy\n2. Then bakery\n10. Finish with water\n\n---\nSee [our offers](https://jm3eia.store/offers) and use `WELCOME`.',
      '## تسوق الأسبوع\nسلة **متوازنة** لشخصين:\n\n- بيض طازج\n- خبز عربي\n  (عبوة ٦)\n- زبدة **Lurpak**\n\n1. ابدأ بالألبان\n2. ثم المخبوزات\n10. وأخيراً الماء\n\n---\nشاهد [عروضنا](https://jm3eia.store/offers) واستخدم `WELCOME`.'), 'deals', 'breakfast');
  }
  if (has(/\blong\b/, /طويل/)) {
    let body = '';
    const unit = t(lang, LONG_EN, LONG_AR);
    for (let i = 1; body.length + unit.length + 12 < 7900; i++) body += (i % 6 === 0 ? `\n\n**${i}.** ` : '') + unit;
    return textPlan(lang, body.trim(), 'deals');
  }
  if (slugs.length) {
    const tools = slugs.map((slug) => productsTool(lang, slug));
    const names = tools.flatMap((tool) => tool.blocks.flatMap((b) => b.products.map((p) => `- ${p.name}`)));
    return {
      tools,
      text: t(lang, `Here are the options available:\n${names.join('\n')}\n\nWould you like to add any of these to your cart?`,
        `هذه الخيارات المتوفرة:\n${names.join('\n')}\n\nهل تريد إضافة أي منها إلى سلتك؟`),
      suggestions: pickChips(lang, 'addButter', 'deals', 'breakfast'),
    };
  }
  return textPlan(lang, t(lang, "Hi! I'm the Hero Assistant. I can find products, suggest recipes, check offers and delivery times, and prepare your cart.",
    'أهلاً! أنا مساعد هيرو. أستطيع البحث عن المنتجات واقتراح الوصفات ومعرفة العروض ومواعيد التوصيل وتجهيز سلتك.'), 'deals', 'breakfast', 'slots', 'addButter');
}
const textPlan = (lang, text, ...chipKeys) => ({ tools: [], text, suggestions: pickChips(lang, ...chipKeys) });

function everythingPlan(api, owner) {
  const { lang } = api;
  const butter = productRow(lang, 'lurpak-butter-200g');
  const eggs = productRow(lang, 'fresh-eggs-30');
  const blocks = [
    { kind: 'products', products: listOf(lang, 'products').slice(0, 6) },
    { kind: 'product_detail', product: eggs },
    { kind: 'cart_action', actionId: crypto.randomBytes(12).toString('hex'), status: 'pending', estimatedTotal: butter.price * 2,
      items: [{ productId: butter._id, variantId: null, quantity: 2, product: butter }] },
    { kind: 'cart_summary', cart: commerce.cartPayload(commerce.cartOf(api.req, api.authed), lang) },
    { kind: 'offers', offers: listOf(lang, 'offers'), couponCode: 'WELCOME' },
    recipeBlock(lang, 'kuwaiti-egg-breakfast'),
    { kind: 'faq', items: FAQ(lang) },
    { kind: 'categories', categories: listOf(lang, 'categories').filter((c) => !c.parentId) },
    { kind: 'brands', brands: listOf(lang, 'brands') },
    { kind: 'delivery_slots', days: commerce.slotDays(lang) },
    { kind: 'delivery_info', areaName: t(lang, 'Salmiya', 'السالمية'), zoneName: t(lang, 'Zone 1', 'المنطقة ١'), fee: 0, etaMinutes: 40 },
    { kind: 'locations', items: locationsOf(lang) },
    { kind: 'error', code: 'TOOL_FAILED', message: t(lang, 'One of the tools failed.', 'فشلت إحدى الأدوات.') },
    { kind: 'future_card', whatever: true },
  ].filter(Boolean);
  if (owner === 'customer') {
    seedOrder(lang, api.customer);
    const order = orderBlockOf(commerce.state.orders[0]);
    blocks.splice(4, 0, { kind: 'order', order }, { kind: 'order_status', order });
  }
  return {
    tools: [{ name: 'search_products', ok: true, blocks }],
    text: t(lang, 'Here is **every card** I can show:\n- products and a proposal\n- your cart, offers and a recipe\n- store answers and delivery details',
      'هذه **كل البطاقات** التي أستطيع عرضها:\n- المنتجات واقتراح للسلة\n- سلتك والعروض ووصفة\n- إجابات المتجر وتفاصيل التوصيل'),
    suggestions: pickChips(lang, 'deals', 'breakfast', 'slots', 'human'),
  };
}

function openTicket(entry) {
  if (entry.conv.status === 'handed_off' && entry.ticket) return entry.ticket;
  const ticket = { ticketId: oid(), ticketNumber: 'T-' + (1000 + ++state.tickets) };
  entry.ticket = ticket;
  entry.conv.status = 'handed_off';
  entry.conv.supportTicketId = ticket.ticketId;
  entry.conv.updatedAt = now();
  return ticket;
}

// --- the stream ------------------------------------------------------------------------------
function tokens(text, lang) {
  const words = text.match(/\s*\S+/g) || [];
  if (lang !== 'ar') return words;
  // Live AR deltas split words ("اقت" + "راح"): half the long words arrive in two pieces.
  return words.flatMap((word, i) => (word.trim().length > 4 && i % 2 === 0 ? [word.slice(0, Math.ceil(word.length / 2)), word.slice(Math.ceil(word.length / 2))] : [word]));
}

function openSse(res) {
  res.writeHead(200, { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache', Connection: 'keep-alive', 'X-Accel-Buffering': 'no' });
  const stream = { gone: false, timers: new Set() };
  res.on('close', () => {
    for (const timer of stream.timers) clearInterval(timer);
    if (!res.writableFinished) stream.gone = true;
  });
  stream.write = (chunk) => { if (!stream.gone && !res.destroyed) res.write(chunk); };
  stream.frame = (event, data) => stream.write(`event: ${event}\ndata: ${JSON.stringify(data)}\n\n`);
  stream.heartbeat = () => stream.timers.add(setInterval(() => stream.write(': ping\n\n'), HEARTBEAT_MS));
  stream.end = () => { for (const timer of stream.timers) clearInterval(timer); if (!res.destroyed) res.end(); };
  stream.write(': connected\n\n');
  return stream;
}

async function runTurn(api, entry, userText, forcedNew) {
  const { res, lang } = api;
  const knobs = state.knobs;
  const failPersist = knobs.failPersist > 0 && knobs.failPersist--;
  const errorFrame = !failPersist && knobs.errorFrame > 0 && knobs.errorFrame--;
  const drop = !failPersist && !errorFrame && knobs.drop > 0 && knobs.drop--;
  const conv = entry.conv;
  const stream = openSse(res);

  const userMessage = message(conv._id, 'user', userText, [{ kind: 'text', text: userText }]);
  entry.messages.push(userMessage);
  Object.assign(conv, { lastMessageAt: userMessage.createdAt, lastMessagePreview: preview(userText), updatedAt: userMessage.createdAt });

  stream.frame('message_start', { conversationId: conv._id });
  stream.frame('user_message', { conversationId: conv._id, message: { ...userMessage, blocks: [] } }); // L14
  if (!knobs.stall) stream.heartbeat();
  await sleep(FIRST_TOKEN_MS + knobs.slow + knobs.stall);

  const script = plan(api, userText, entry.owner, entry);
  const streamed = [];
  for (const tool of script.tools) {
    const id = callId();
    stream.frame('tool_start', { name: tool.name, callId: id });
    await sleep(TOOL_MS);
    stream.frame('tool_end', { name: tool.name, callId: id, ok: tool.ok });
    for (const block of tool.blocks) {
      streamed.push(block);
      stream.frame('block', { block }); // L4: cards stream before the words
    }
  }
  const words = tokens(script.text, lang);
  for (let i = 0; i < words.length; i++) {
    if (i === Math.floor(words.length / 2)) {
      // A network drop: the socket dies, the server still finishes and saves the reply.
      if (drop) res.destroy();
      if (errorFrame) {
        stream.frame('error', { code: knobs.errorCode, message: 'Something went wrong' }); // N4: English in both languages
        return stream.end();
      }
    }
    stream.frame('text_delta', { delta: words[i] });
    await sleep(DELTA_MS);
  }
  if (failPersist) {
    // L7: everything streamed, then the save fails: nothing stored, the proposal cannot be confirmed.
    stream.frame('error', { code: 'INTERNAL_ERROR', message: 'Document failed validation' });
    return stream.end();
  }

  const blocks = [{ kind: 'text', text: script.text }, ...streamed];
  if (script.suggestions.length) blocks.push({ kind: 'actions', suggestions: script.suggestions }); // L5: chips only here
  const reply = message(conv._id, 'assistant', script.text, blocks, userMessage.createdAt); // L15
  reply.updatedAt = now();
  entry.messages.push(reply);
  for (const block of streamed) {
    if (block.kind === 'cart_action') {
      state.actions.set(block.actionId, { owner: entry.owner, convId: conv._id, messageId: reply._id, block, status: 'pending' });
    }
  }
  conv.messageCount += 2; // L12: only finished turns count
  conv.lastMessagePreview = preview(script.text);
  conv.usage.promptTokens += 4000 + userText.length;
  conv.usage.completionTokens += Math.ceil(script.text.length / 4);
  conv.updatedAt = reply.updatedAt;
  if (entry.messages.length >= MAX_MESSAGES) conv.status = 'closed';
  stream.frame('message_end', { conversationId: conv._id, message: reply });
  stream.end();
}

// --- routes --------------------------------------------------------------------------------
function validation(api, key, text) {
  return api.fail(400, 'VALIDATION_ERROR', t(api.lang, 'Validation failed', 'فشل التحقق'), [{ key, message: text }]);
}
function takeFail(route) {
  const knob = state.knobs.fail[route];
  if (!knob || knob.n <= 0) return null;
  knob.n--;
  return knob.status;
}
function later(fn) {
  if (state.knobs.delay > 0) setTimeout(fn, state.knobs.delay);
  else fn();
  return true;
}

function listConversations(api, owner) {
  const { query } = api;
  const page = query.page === undefined ? 1 : Number(query.page);
  const limit = query.limit === undefined ? 20 : Number(query.limit);
  if (!Number.isInteger(page) || page < 1) return validation(api, 'page', 'must be >= 1');
  if (!Number.isInteger(limit) || limit < 1 || limit > 100) return validation(api, 'limit', 'must be <= 100');
  if (query.search !== undefined && (query.search.length < 1 || query.search.length > 120)) return validation(api, 'search', 'must NOT have more than 120 characters');
  const rows = owner
    ? [...state.conversations.values()].filter((e) => e.owner === owner).map((e) => e.conv)
      .sort((a, b) => Date.parse(b.lastMessageAt) - Date.parse(a.lastMessageAt))
    : []; // L10: no identity -> nothing
  return api.ok({ data: rows.slice((page - 1) * limit, page * limit), pagination: { total: rows.length, page, limit, hasMore: page * limit < rows.length } }, 'DATA_LOADED');
}

function sendMessage(api, owner) {
  const { body, lang, res } = api;
  if (state.knobs.validation > 0) { state.knobs.validation--; return validation(api, 'message', 'must NOT have more than 2000 characters'); }
  if (typeof body.message !== 'string') return validation(api, 'message', "must have required property 'message'");
  const text = body.message.trim();
  if (!text) return validation(api, 'message', 'must NOT have fewer than 1 characters');
  if (codePoints(text) > MAX_PROMPT) return validation(api, 'message', 'must NOT have more than 2000 characters');
  const id = body.conversationId;
  if (id !== undefined && id !== null && (typeof id !== 'string' || !HEX24.test(id))) return validation(api, 'conversationId', 'must match pattern "^[0-9a-fA-F]{24}$"');

  let entry = null;
  if (id) {
    entry = owned(id, owner);
    if (!entry) {
      // L9: the stream opens, then a single error frame.
      const stream = openSse(res);
      stream.frame('error', { code: 'RESOURCE_NOT_FOUND', message: 'Conversation not found' });
      stream.end();
      return true;
    }
    if (state.knobs.closed > 0) { state.knobs.closed--; entry.conv.status = 'closed'; }
    if (entry.conv.status === 'closed') entry = null; // the message goes to a NEW conversation
  }
  if (!entry) entry = newConversation(owner, lang, text);
  runTurn(api, entry, text).catch((error) => { console.error('assistant turn failed', error); if (!res.destroyed) res.destroy(); });
  return true;
}

function confirmAction(api, owner, actionId) {
  const { lang } = api;
  if (actionId.length < 8 || actionId.length > 64) return validation(api, 'actionId', 'must NOT have fewer than 8 characters');
  const status = takeFail('confirm');
  return later(() => {
    if (status) return api.fail(status, FAIL_CODES[status] || 'INTERNAL_ERROR', t(lang, 'Something went wrong', 'حدث خطأ ما'));
    const action = state.actions.get(actionId);
    if (!action || action.owner !== owner || action.status !== 'pending') return api.fail(404, 'RESOURCE_NOT_FOUND', 'Action not found');
    const items = action.block.items.map(({ productId, variantId, quantity }) => ({ productId, variantId: variantId || null, quantity }));
    handleCommerce({
      req: { method: 'POST', headers: api.req.headers }, pathname: '/v1/cart/items', query: {}, body: { items },
      lang, authed: api.authed, customer: api.customer,
      ok: (cart) => {
        action.status = 'confirmed';
        const confirmed = { ...action.block, status: 'confirmed' };
        const entry = state.conversations.get(action.convId);
        const stored = entry && entry.messages.find((m) => m._id === action.messageId);
        if (stored) stored.blocks = stored.blocks.map((b) => (b.kind === 'cart_action' && b.actionId === actionId ? confirmed : b));
        api.ok({ message: t(lang, 'Added to your cart', 'تمت الإضافة إلى سلتك'), blocks: [{ kind: 'cart_summary', cart }, confirmed] }, 'UPDATED');
      },
      fail: (failStatus, code, text, data) => api.fail(failStatus, code, text, data),
    });
  });
}

function handoff(api, owner, id) {
  const { body, lang } = api;
  for (const [key, max] of [['subject', 120], ['category', 64], ['subcategory', 64]]) {
    if (key in body && (typeof body[key] !== 'string' || body[key].length < 1 || body[key].length > max)) return validation(api, key, `must NOT have more than ${max} characters`);
  }
  const status = takeFail('handoff');
  return later(() => {
    if (status) return api.fail(status, FAIL_CODES[status] || 'INTERNAL_ERROR', t(lang, 'Something went wrong', 'حدث خطأ ما'));
    const entry = owned(id, owner);
    if (!entry) return api.fail(404, 'RESOURCE_NOT_FOUND', 'Conversation not found');
    const again = entry.conv.status === 'handed_off' && entry.ticket;
    const ticket = openTicket(entry);
    const text = t(lang, `Our support team will reply here. Your ticket is ${ticket.ticketNumber}.`, `سيرد عليك فريق الدعم هنا. رقم تذكرتك ${ticket.ticketNumber}.`);
    if (!again) entry.messages.push(message(entry.conv._id, 'assistant', text, [{ kind: 'text', text }, { kind: 'handoff', ...ticket }]));
    api.ok({ ...ticket, message: text }, 'CREATED');
  });
}

function feedback(api, owner, id) {
  const { body, lang } = api;
  if (!('feedback' in body) || ![null, 'up', 'down'].includes(body.feedback)) return validation(api, 'feedback', 'must be equal to one of the allowed values');
  const status = takeFail('feedback');
  return later(() => {
    if (status) return api.fail(status, FAIL_CODES[status] || 'INTERNAL_ERROR', t(lang, 'Something went wrong', 'حدث خطأ ما'));
    for (const entry of state.conversations.values()) {
      if (entry.owner !== owner || !owner) continue;
      const found = entry.messages.find((m) => m._id === id);
      if (found) { // L16: user messages take it too
        found.feedback = body.feedback;
        found.updatedAt = now();
        return api.ok({ message: t(lang, 'Thanks for your feedback', 'شكراً على ملاحظاتك') }, 'UPDATED');
      }
    }
    return api.fail(404, 'RESOURCE_NOT_FOUND', 'Message not found');
  });
}

// --- side effects on other routes ------------------------------------------------------------
function mergeGuest(guest) {
  const from = 'guest:' + guest;
  for (const entry of state.conversations.values()) if (entry.owner === from) entry.owner = 'customer';
  for (const action of state.actions.values()) if (action.owner === from) action.owner = 'customer';
}
function patchInit(res) {
  const end = res.end.bind(res);
  res.end = (chunk, ...rest) => {
    try {
      const body = JSON.parse(chunk);
      const store = body.results && body.results.store;
      if (store) {
        store.assistant = { enabled: !state.knobs.disabled, allowGuests: !state.knobs.guestsOff };
        store.featureFlags = { ...(store.featureFlags || {}), assistant: state.knobs.featureFlag };
      }
      return end(JSON.stringify(body), ...rest);
    } catch {
      return end(chunk, ...rest);
    }
  };
}

function seed(owner, count) {
  const topics = [['Show me butter and eggs', 'أرني الزبدة والبيض'], ['Suggest a breakfast recipe', 'اقترح وصفة فطور'], ['What delivery slots are available?', 'ما هي مواعيد التوصيل المتاحة؟'], ['Track my order', 'تتبع طلبي'], ['Current offers', 'العروض الحالية']];
  for (let i = 0; i < count; i++) {
    const lang = i % 3 === 2 ? 'ar' : 'en';
    const [en, ar] = topics[i % topics.length];
    const entry = newConversation(owner, lang, t(lang, en, ar) + ` #${i + 1}`);
    const at = new Date(Date.now() - i * 26 * 3600e3).toISOString(); // spread over the last weeks
    const user = message(entry.conv._id, 'user', entry.conv.title, [{ kind: 'text', text: entry.conv.title }], at);
    const text = t(lang, 'Here is what I found for you.', 'هذا ما وجدته لك.');
    entry.messages.push(user, message(entry.conv._id, 'assistant', text, [{ kind: 'text', text }], at));
    Object.assign(entry.conv, { messageCount: 2, lastMessageAt: at, lastMessagePreview: text, createdAt: at, updatedAt: at, status: i % 7 === 6 ? 'closed' : 'active' });
  }
}

function handleAdminKnob(api) {
  const { pathname, query } = api;
  const knobs = state.knobs;
  const parts = pathname.split('/').slice(3); // ['fail-persist', '1'] …
  const [name, a, b, c] = parts;
  const n = (value) => Math.max(0, Number(value) || 0);
  switch (name) {
    case undefined: break;
    case 'reset': state.conversations.clear(); state.actions.clear(); state.tickets = 0; state.knobs = freshKnobs(); break;
    case 'fail-persist': knobs.failPersist = n(a); break;
    case 'error-frame': knobs.errorFrame = n(a); knobs.errorCode = query.code || 'INTERNAL_ERROR'; break;
    case 'drop-mid-stream': knobs.drop = n(a); break;
    case 'slow': knobs.slow = n(a); break;
    case 'stall': knobs.stall = n(a); break;
    case 'closed': knobs.closed = n(a); break;
    case 'disabled': knobs.disabled = n(a); break;
    case 'guests-off': knobs.guestsOff = a === '1'; break;
    case 'flag': knobs.featureFlag = a !== '0'; break;
    case 'rate-limit': knobs.rateLimit = n(a); break;
    case 'validation': knobs.validation = n(a); break;
    case 'delay': knobs.delay = n(a); break;
    case 'strict-auth': knobs.strictAuth = a === '1'; break;
    case 'fail': knobs.fail[a] = { status: n(b), n: n(c) }; break;
    case 'expire-actions': for (const action of state.actions.values()) if (action.status === 'pending') action.status = 'expired'; break;
    case 'seed': seed(!query.owner || query.owner === 'customer' ? 'customer' : 'guest:' + query.owner, n(a)); break;
    default: return api.fail(404, 'RESOURCE_NOT_FOUND', 'Unknown assistant knob: ' + name);
  }
  return api.ok({
    knobs: state.knobs,
    conversations: [...state.conversations.values()].map((e) => ({ id: e.conv._id, owner: e.owner, status: e.conv.status, messages: e.messages.length, title: e.conv.title })),
    actions: [...state.actions.entries()].map(([id, action]) => ({ id, owner: action.owner, status: action.status })),
    tickets: state.tickets,
  });
}

/// True when this module answered (or will answer) the request.
function handleAssistant(dispatch) {
  // Every answer path returns true, so server.js stops there.
  const api = {
    ...dispatch,
    ok: (...args) => (dispatch.ok(...args), true),
    fail: (...args) => (dispatch.fail(...args), true),
  };
  const { req, pathname, body } = api;
  if (pathname === '/__admin/assistant' || pathname.startsWith('/__admin/assistant/')) return handleAdminKnob(api);
  if (req.method === 'POST' && pathname === '/v1/auth/verify-otp') {
    const guest = req.headers['x-assistant-guest'];
    if (guest && body.code === api.otp) mergeGuest(guest);
    return false;
  }
  if (req.method === 'GET' && pathname === '/v1/init') { patchInit(api.res); return false; }
  if (!pathname.startsWith('/v1/assistant/')) return false;

  const { lang } = api;
  if (state.knobs.disabled) {
    const status = state.knobs.disabled;
    return api.fail(status, FAIL_CODES[status] || 'SERVICE_UNAVAILABLE', t(lang, 'The assistant is not available', 'المساعد غير متاح'));
  }
  if ((state.knobs.rateLimit > 0 && state.knobs.rateLimit--) || (api.takeRateLimit && api.takeRateLimit())) {
    return api.fail(429, 'RATE_LIMITED', t(lang, 'Too many requests', 'طلبات كثيرة جدًا'), [], { 'Retry-After': '1' });
  }
  const who = identity(api);
  if (who.status) return api.fail(who.status, who.code, who.message);
  const owner = who.owner;

  if (req.method === 'GET' && pathname === '/v1/assistant/conversations') {
    const status = takeFail('list');
    return later(() => (status ? api.fail(status, FAIL_CODES[status] || 'INTERNAL_ERROR', t(lang, 'Something went wrong', 'حدث خطأ ما')) : listConversations(api, owner)));
  }
  const detail = pathname.match(/^\/v1\/assistant\/conversations\/([^/]+)$/);
  if (req.method === 'GET' && detail) {
    if (!HEX24.test(detail[1])) return validation(api, 'id', 'must match pattern "^[0-9a-fA-F]{24}$"');
    const status = takeFail('detail');
    return later(() => {
      if (status) return api.fail(status, FAIL_CODES[status] || 'INTERNAL_ERROR', t(lang, 'Something went wrong', 'حدث خطأ ما'));
      const entry = owned(detail[1], owner);
      if (!entry) return api.fail(404, 'RESOURCE_NOT_FOUND', 'Conversation not found');
      return api.ok({ conversation: entry.conv, messages: entry.messages }, 'DATA_LOADED');
    });
  }
  if (req.method === 'POST' && pathname === '/v1/assistant/messages') return sendMessage(api, owner);
  const confirm = pathname.match(/^\/v1\/assistant\/actions\/([^/]+)\/confirm$/);
  if (req.method === 'POST' && confirm) return confirmAction(api, owner, confirm[1]);
  const hand = pathname.match(/^\/v1\/assistant\/conversations\/([^/]+)\/handoff$/);
  if (req.method === 'POST' && hand) {
    if (!HEX24.test(hand[1])) return validation(api, 'id', 'must match pattern "^[0-9a-fA-F]{24}$"');
    return handoff(api, owner, hand[1]);
  }
  const rate = pathname.match(/^\/v1\/assistant\/messages\/([^/]+)\/feedback$/);
  if (req.method === 'POST' && rate) {
    if (!HEX24.test(rate[1])) return validation(api, 'id', 'must match pattern "^[0-9a-fA-F]{24}$"');
    return feedback(api, owner, rate[1]);
  }
  return api.fail(404, 'RESOURCE_NOT_FOUND', 'Not found');
}

module.exports = { handleAssistant, state };
