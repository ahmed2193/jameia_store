// Live probe for POST /v1/assistant/messages (SSE). Prints every raw frame with elapsed ms.
// Guest:  node assistant_sse_probe.js <32-hex guest id> en "Show me butter" [conversationId|-] [frames.json]
// Signed in: BEARER=<access token> node assistant_sse_probe.js - en "hi"
// Mock:   BASE=http://127.0.0.1:5055 node assistant_sse_probe.js <guest> en "hi"
// Every call to the live host creates a real conversation (and LLM usage): keep live runs few.
const fs = require('fs');
const [guest, lang, message, conversationId, outFile] = process.argv.slice(2);
const base = process.env.BASE || 'https://api.jm3eia.store';

(async () => {
  const t0 = Date.now();
  const headers = {
    'Content-Type': 'application/json',
    Accept: 'text/event-stream',
    'Accept-Language': lang,
  };
  if (guest && guest !== '-') headers['X-Assistant-Guest'] = guest;
  if (process.env.BEARER) headers.Authorization = `Bearer ${process.env.BEARER}`;
  const body = { message };
  if (conversationId && conversationId !== '-') body.conversationId = conversationId;
  const res = await fetch(`${base}/v1/assistant/messages`, { method: 'POST', headers, body: JSON.stringify(body) });
  console.log(`HTTP ${res.status} ${res.headers.get('content-type')} (${Date.now() - t0}ms)`);
  for (const h of ['x-ratelimit-limit', 'x-ratelimit-remaining', 'cache-control', 'x-accel-buffering']) {
    if (res.headers.get(h)) console.log(`  ${h}: ${res.headers.get(h)}`);
  }
  if (!res.headers.get('content-type')?.includes('event-stream')) {
    console.log(await res.text());
    return;
  }
  const frames = [];
  const decoder = new TextDecoder();
  let buf = '';
  for await (const chunk of res.body) {
    buf += decoder.decode(chunk, { stream: true });
    let idx;
    while ((idx = buf.indexOf('\n\n')) >= 0) {
      const raw = buf.slice(0, idx);
      buf = buf.slice(idx + 2);
      const f = { ms: Date.now() - t0, event: 'message', data: '' , comment: null};
      for (const line of raw.split('\n')) {
        if (line.startsWith(':')) f.comment = line;
        else if (line.startsWith('event:')) f.event = line.slice(6).trim();
        else if (line.startsWith('data:')) f.data += (f.data ? '\n' : '') + line.slice(5).trimStart();
        else if (line.startsWith('id:')) f.id = line.slice(3).trim();
      }
      frames.push(f);
      const preview = f.event === 'text_delta' ? f.data : f.data.slice(0, 400);
      console.log(`[${f.ms}ms] ${f.comment ?? ''}event=${f.event}${f.id ? ' id=' + f.id : ''} data=${preview}`);
    }
  }
  console.log(`stream closed after ${Date.now() - t0}ms, ${frames.length} frames`);
  if (outFile) fs.writeFileSync(outFile, JSON.stringify(frames, null, 1));
})().catch((e) => { console.error('ERR', e); process.exit(1); });
