#!/usr/bin/env node
// Reads the live jm3eia OpenAPI spec and prints a route the way a Flutter
// datasource author needs it: auth, params, request body, and the envelope's
// `results` shape (what `ApiConsumer` hands the datasource).
//
//   node openapi_route.js                 # every route, grouped by tag
//   node openapi_route.js orders          # routes whose path contains "orders"
//   node openapi_route.js "GET /v1/cart"  # one method + path fragment
//
// Env: OPENAPI_URL (default https://api.jm3eia.store/docs/json)
//      OPENAPI_FILE (read a saved copy instead of the network)
'use strict';

const fs = require('fs');

const SPEC_URL = process.env.OPENAPI_URL || 'https://api.jm3eia.store/docs/json';
const METHODS = ['get', 'post', 'put', 'patch', 'delete'];
const OBJECT_ID = '^[0-9a-fA-F]{24}$';

async function loadSpec() {
  if (process.env.OPENAPI_FILE) {
    return JSON.parse(fs.readFileSync(process.env.OPENAPI_FILE, 'utf8'));
  }
  const response = await fetch(SPEC_URL);
  if (!response.ok) throw new Error(`${SPEC_URL} -> HTTP ${response.status}`);
  return response.json();
}

function resolveRef(spec, schema) {
  if (!schema || !schema.$ref) return schema;
  return schema.$ref
    .replace(/^#\//, '')
    .split('/')
    .reduce((node, key) => (node ? node[key] : undefined), spec);
}

// JSON schema -> compact TypeScript-like text.
function render(spec, raw, depth) {
  const schema = resolveRef(spec, raw);
  if (!schema) return 'unknown';
  const pad = '  '.repeat(depth);

  const union = schema.anyOf || schema.oneOf;
  if (union) {
    const parts = [...new Set(union.map((item) => render(spec, item, depth)))];
    return parts.join(' | ');
  }
  if (schema.allOf) {
    return schema.allOf.map((item) => render(spec, item, depth)).join(' & ');
  }
  if (schema.enum) {
    return schema.enum.map((value) => JSON.stringify(value)).join(' | ');
  }
  if (schema.type === 'null') return 'null';
  if (schema.type === 'array') {
    const item = render(spec, schema.items, depth);
    return /[|&*]/.test(item) ? `(${item})[]` : `${item}[]`;
  }
  if (schema.type === 'object' || schema.properties) {
    const properties = schema.properties || {};
    const keys = Object.keys(properties);
    if (keys.length === 0) {
      return schema.additionalProperties ? 'Record<string, unknown>' : '{}';
    }
    const required = new Set(schema.required || []);
    const lines = keys.map((key) => {
      const optional = required.has(key) ? '' : '?';
      return `${pad}  ${key}${optional}: ${render(spec, properties[key], depth + 1)}`;
    });
    return `{\n${lines.join('\n')}\n${pad}}`;
  }
  return primitive(schema);
}

function primitive(schema) {
  if (schema.pattern === OBJECT_ID) return 'ObjectId';
  let text = schema.type || 'unknown';
  const notes = [];
  if (schema.format) notes.push(schema.format);
  if (schema.minLength != null || schema.maxLength != null) {
    notes.push(`len ${schema.minLength ?? 0}..${schema.maxLength ?? ''}`);
  }
  if (schema.minimum != null || schema.maximum != null) {
    notes.push(`${schema.minimum ?? ''}..${schema.maximum ?? ''}`);
  }
  if (schema.pattern) notes.push(`/${schema.pattern}/`);
  if (schema.default !== undefined) notes.push(`default ${JSON.stringify(schema.default)}`);
  if (notes.length) text += ` /* ${notes.join(', ')} */`;
  return text;
}

// The envelope's `results` member (minus the `null` branch of error replies).
function resultsOf(spec, responseSchema) {
  const schema = resolveRef(spec, responseSchema);
  const results = schema && schema.properties && schema.properties.results;
  if (!results) return schema;
  const union = results.anyOf || results.oneOf;
  if (!union) return results;
  const real = union.filter((item) => item.type !== 'null');
  return real.length === 1 ? real[0] : { anyOf: real };
}

function describe(spec, method, path, operation) {
  const out = [];
  const secured = Array.isArray(operation.security) && operation.security.length > 0;
  out.push(`${method.toUpperCase()} ${path}`);
  if (operation.summary) out.push(`  summary : ${operation.summary}`);
  if (operation.description) out.push(`  notes   : ${operation.description}`);
  out.push(`  tag     : ${(operation.tags || ['-']).join(', ')}`);
  // The published spec declares no `security` anywhere, so absence proves
  // nothing: the section comments in `EndPoints` say public / guest / customer.
  out.push(`  auth    : ${secured ? 'Bearer required' : 'not declared in the spec — see the section comment in core/network/end_points.dart'}`);

  for (const where of ['path', 'query', 'header']) {
    const params = (operation.parameters || []).filter((p) => p.in === where);
    if (params.length === 0) continue;
    out.push(`  ${where}:`);
    for (const param of params) {
      const optional = param.required ? '' : '?';
      out.push(`    ${param.name}${optional}: ${render(spec, param.schema, 2)}`);
    }
  }

  const body = operation.requestBody && operation.requestBody.content;
  if (body) {
    const [mediaType, media] = Object.entries(body)[0];
    out.push(`  body (${mediaType}): ${render(spec, media.schema, 1)}`);
  }

  for (const [status, response] of Object.entries(operation.responses || {})) {
    const content = response.content || {};
    const [mediaType, media] = Object.entries(content)[0] || [];
    if (!media) {
      out.push(`  ${status}: ${response.description || '(no body)'}`);
    } else if (mediaType === 'application/json') {
      out.push(`  ${status} results: ${render(spec, resultsOf(spec, media.schema), 1)}`);
    } else {
      out.push(`  ${status} (${mediaType}): stream / raw body — use EventStreamClient`);
    }
  }
  return out.join('\n');
}

async function main() {
  const filter = process.argv.slice(2).join(' ').trim().toLowerCase();
  const spec = await loadSpec();
  const routes = [];
  for (const [path, item] of Object.entries(spec.paths || {})) {
    for (const method of METHODS) {
      if (item[method]) routes.push({ method, path, operation: item[method] });
    }
  }

  if (!filter) {
    const byTag = new Map();
    for (const route of routes) {
      const tag = (route.operation.tags || ['-'])[0];
      if (!byTag.has(tag)) byTag.set(tag, []);
      byTag.get(tag).push(route);
    }
    for (const [tag, list] of byTag) {
      console.log(`\n# ${tag}`);
      for (const { method, path, operation } of list) {
        console.log(`  ${method.toUpperCase().padEnd(6)} ${path}  ${operation.summary ? '— ' + operation.summary : ''}`);
      }
    }
    console.log(`\n${routes.length} routes. Pass a filter to see params / body / results.`);
    return;
  }

  const matches = routes.filter(({ method, path }) =>
    `${method} ${path}`.toLowerCase().includes(filter));
  if (matches.length === 0) {
    console.error(`no route matches "${filter}"`);
    process.exit(1);
  }
  console.log(matches.map((r) => describe(spec, r.method, r.path, r.operation)).join('\n\n'));
}

main().catch((error) => {
  console.error(String(error && error.message ? error.message : error));
  process.exit(1);
});
