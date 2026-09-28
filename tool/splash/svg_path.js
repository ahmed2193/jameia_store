// Minimal SVG path reader for the splash tools: turns a path's `d` (plus a
// translate) into absolute segments, and those into Dart `Path` calls.
'use strict';

const NUM = /-?(?:\d+\.?\d*|\.\d+)(?:e[-+]?\d+)?/gi;

/** Tokenises `d` into [command, ...numbers] groups. */
function tokens(d) {
  const out = [];
  const re = /([MmLlHhVvCcSsQqTtAaZz])([^MmLlHhVvCcSsQqTtAaZz]*)/g;
  let m;
  while ((m = re.exec(d))) {
    const cmd = m[1];
    if (cmd === 'A' || cmd === 'a') {
      // Arc flags may be written without separators ("0 011.5 2").
      const nums = [];
      const s = m[2];
      let i = 0;
      const next = () => {
        while (i < s.length && /[\s,]/.test(s[i])) i++;
        const idx = nums.length % 7;
        if (idx === 3 || idx === 4) {
          const v = Number(s[i]);
          i++;
          return v;
        }
        NUM.lastIndex = i;
        const r = NUM.exec(s);
        if (!r || r.index !== i) return null;
        i = NUM.lastIndex;
        return Number(r[0]);
      };
      for (;;) {
        while (i < s.length && /[\s,]/.test(s[i])) i++;
        if (i >= s.length) break;
        const v = next();
        if (v === null || Number.isNaN(v)) break;
        nums.push(v);
      }
      out.push([cmd, ...nums]);
    } else {
      out.push([cmd, ...(m[2].match(NUM) || []).map(Number)]);
    }
  }
  return out;
}

/**
 * Absolute segments: {op:'M'|'L'|'C'|'Q'|'A'|'Z', pts:[...]} with every
 * point already moved by (dx, dy).
 */
function segments(d, dx = 0, dy = 0) {
  const segs = [];
  let x = 0;
  let y = 0;
  let sx = 0;
  let sy = 0;
  let lastC = null; // last cubic control point (for S)
  let lastQ = null; // last quadratic control point (for T)
  const P = (px, py) => [px + dx, py + dy];
  for (const [cmd, ...n] of tokens(d)) {
    const rel = cmd === cmd.toLowerCase();
    const C = cmd.toUpperCase();
    const size = { M: 2, L: 2, H: 1, V: 1, C: 6, S: 4, Q: 4, T: 2, A: 7, Z: 0 }[C];
    if (C === 'Z') {
      segs.push({ op: 'Z' });
      x = sx;
      y = sy;
      lastC = lastQ = null;
      continue;
    }
    for (let k = 0; k < n.length; k += size) {
      const a = n.slice(k, k + size);
      const ox = rel ? x : 0;
      const oy = rel ? y : 0;
      let op = C;
      if (C === 'M' && k > 0) op = 'L';
      if (op === 'M') {
        x = a[0] + ox;
        y = a[1] + oy;
        sx = x;
        sy = y;
        segs.push({ op: 'M', pts: [P(x, y)] });
        lastC = lastQ = null;
      } else if (op === 'L' || op === 'H' || op === 'V') {
        if (op === 'L') {
          x = a[0] + ox;
          y = a[1] + oy;
        } else if (op === 'H') x = a[0] + ox;
        else y = a[0] + oy;
        segs.push({ op: 'L', pts: [P(x, y)] });
        lastC = lastQ = null;
      } else if (op === 'C' || op === 'S') {
        let c1;
        let c2;
        let e;
        if (op === 'C') {
          c1 = [a[0] + ox, a[1] + oy];
          c2 = [a[2] + ox, a[3] + oy];
          e = [a[4] + ox, a[5] + oy];
        } else {
          c1 = lastC ? [2 * x - lastC[0], 2 * y - lastC[1]] : [x, y];
          c2 = [a[0] + ox, a[1] + oy];
          e = [a[2] + ox, a[3] + oy];
        }
        segs.push({ op: 'C', pts: [P(...c1), P(...c2), P(...e)] });
        lastC = c2;
        lastQ = null;
        [x, y] = e;
      } else if (op === 'Q' || op === 'T') {
        let c;
        let e;
        if (op === 'Q') {
          c = [a[0] + ox, a[1] + oy];
          e = [a[2] + ox, a[3] + oy];
        } else {
          c = lastQ ? [2 * x - lastQ[0], 2 * y - lastQ[1]] : [x, y];
          e = [a[0] + ox, a[1] + oy];
        }
        segs.push({ op: 'Q', pts: [P(...c), P(...e)] });
        lastQ = c;
        lastC = null;
        [x, y] = e;
      } else if (op === 'A') {
        const e = [a[5] + ox, a[6] + oy];
        segs.push({ op: 'A', rx: a[0], ry: a[1], rot: a[2], large: !!a[3], sweep: !!a[4], pts: [P(...e)] });
        [x, y] = e;
        lastC = lastQ = null;
      }
    }
  }
  return segs;
}

/** Bounding box of the segments' points (control points included). */
function bounds(segs) {
  let l = Infinity;
  let t = Infinity;
  let r = -Infinity;
  let b = -Infinity;
  for (const s of segs) {
    for (const [px, py] of s.pts || []) {
      l = Math.min(l, px);
      t = Math.min(t, py);
      r = Math.max(r, px);
      b = Math.max(b, py);
    }
  }
  return { l, t, r, b };
}

const f = (v) => {
  const s = (Math.round(v * 1000) / 1000).toString();
  return s.includes('.') || s.includes('e') ? s : `${s}.0`;
};

/** Dart cascade calls (`..moveTo(...)`) for the segments, moved by (ox, oy). */
function dartCalls(segs, ox = 0, oy = 0) {
  const q = ([x, y]) => `${f(x - ox)}, ${f(y - oy)}`;
  return segs
    .map((s) => {
      switch (s.op) {
        case 'M':
          return `..moveTo(${q(s.pts[0])})`;
        case 'L':
          return `..lineTo(${q(s.pts[0])})`;
        case 'C':
          return `..cubicTo(${q(s.pts[0])}, ${q(s.pts[1])}, ${q(s.pts[2])})`;
        case 'Q':
          return `..quadraticBezierTo(${q(s.pts[0])}, ${q(s.pts[1])})`;
        case 'A':
          return `..arcToPoint(Offset(${q(s.pts[0])}), radius: const Radius.elliptical(${f(s.rx)}, ${f(s.ry)}), rotation: ${f(s.rot)}, largeArc: ${s.large}, clockwise: ${s.sweep})`;
        default:
          return '..close()';
      }
    })
    .join('');
}

/** SVG `d` (absolute, no arcs flattened) for previews. */
function svgD(segs) {
  const q = ([x, y]) => `${x.toFixed(3)} ${y.toFixed(3)}`;
  return segs
    .map((s) => {
      switch (s.op) {
        case 'M':
          return `M${q(s.pts[0])}`;
        case 'L':
          return `L${q(s.pts[0])}`;
        case 'C':
          return `C${s.pts.map(q).join(' ')}`;
        case 'Q':
          return `Q${s.pts.map(q).join(' ')}`;
        case 'A':
          return `A${s.rx} ${s.ry} ${s.rot} ${s.large ? 1 : 0} ${s.sweep ? 1 : 0} ${q(s.pts[0])}`;
        default:
          return 'Z';
      }
    })
    .join('');
}

module.exports = { segments, bounds, dartCalls, svgD };
