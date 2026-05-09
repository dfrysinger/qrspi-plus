#!/usr/bin/env node
// run-smoke-checks.mjs — QRSPI runtime gate helper.
//
// Usage:
//   node scripts/run-smoke-checks.mjs --task-spec <path> [--port <n>] [--base-url <url>]
//
// Reads the first ```yaml ... ``` fenced block in the task spec that contains
// `smoke_checks:`, parses a minimal YAML subset, fetches each check against
// the running dev server, and asserts the declared contracts.
//
// Pure Node 18+ stdlib. No npm dependencies.

import { readFileSync } from 'node:fs';
import { exit } from 'node:process';

// ---------------------------------------------------------------------------
// Argument parsing
// ---------------------------------------------------------------------------

function parseArgs(argv) {
  const args = { taskSpec: null, baseUrl: 'http://localhost:3000', port: null };
  let i = 0;
  while (i < argv.length) {
    const arg = argv[i];
    if (arg === '--task-spec' && i + 1 < argv.length) {
      args.taskSpec = argv[i + 1];
      i += 2;
    } else if (arg === '--base-url' && i + 1 < argv.length) {
      args.baseUrl = argv[i + 1];
      i += 2;
    } else if (arg === '--port' && i + 1 < argv.length) {
      args.port = argv[i + 1];
      i += 2;
    } else {
      i++;
    }
  }
  return args;
}

// ---------------------------------------------------------------------------
// YAML block extraction
// ---------------------------------------------------------------------------

/**
 * Find the first ```yaml ... ``` fenced block whose body contains
 * `smoke_checks:` and return the body text (without the fence lines).
 */
function extractSmokeYamlBlock(content) {
  // Match fenced yaml blocks (```yaml ... ```)
  const fencePattern = /^```yaml\s*\n([\s\S]*?)^```\s*$/gm;
  let match;
  while ((match = fencePattern.exec(content)) !== null) {
    const body = match[1];
    if (body.includes('smoke_checks:')) {
      return body;
    }
  }
  return null;
}

// ---------------------------------------------------------------------------
// Minimal YAML parser
// ---------------------------------------------------------------------------
//
// Supported subset:
//   - Top-level scalar keys: `key: value` or `key:` (mapping start)
//   - List of mapping entries at indent 2: `  - key: value`
//   - Key-value pairs inside list entries at indent 4: `    key: value`
//   - Lists of scalars under expect_body_contains / expect_body_not_contains:
//       `    - "string"` or `    - unquoted` (indent 4 or 6)
//   - Scalar types: integer (digits only), double-quoted string, unquoted string
//   - Comments: lines starting with `#` (after stripping leading whitespace)
//
// Returns: { smoke_checks: [...], smoke_auth: {...} | undefined }

function parseMinimalYaml(text, filePath) {
  const lines = text.split('\n');
  const result = {};

  // Tracks current parsing context
  let topKey = null;           // current top-level key
  let currentList = null;      // reference to the list we're building (for top-level lists)
  let currentListItem = null;  // current object inside the list
  let inScalarList = null;     // { listRef, key } when building a scalar sub-list
  let topMapping = null;       // reference to a top-level mapping (for smoke_auth etc.)

  function parseScalar(raw) {
    const trimmed = raw.trim();
    if (trimmed === '') return '';
    // Double-quoted string — process YAML escape sequences (\\, \n, \t, etc.)
    if (trimmed.startsWith('"') && trimmed.endsWith('"')) {
      const inner = trimmed.slice(1, -1);
      // Process common YAML escape sequences in double-quoted strings
      return inner
        .replace(/\\n/g, '\n')
        .replace(/\\t/g, '\t')
        .replace(/\\r/g, '\r')
        .replace(/\\\\/g, '\x00BACKSLASH\x00')  // protect \\ temporarily
        .replace(/\\(.)/g, '$1')                // strip unrecognized escapes
        .replace(/\x00BACKSLASH\x00/g, '\\');   // restore literal backslash
    }
    // Single-quoted string (no escaping except '' → ')
    if (trimmed.startsWith("'") && trimmed.endsWith("'")) {
      return trimmed.slice(1, -1).replace(/''/g, "'");
    }
    // Integer
    if (/^\d+$/.test(trimmed)) {
      return parseInt(trimmed, 10);
    }
    // Unquoted string (trim whitespace)
    return trimmed;
  }

  for (let lineNo = 0; lineNo < lines.length; lineNo++) {
    const rawLine = lines[lineNo];
    const line = rawLine.trimEnd();

    // Empty lines and comments
    if (line.trim() === '' || line.trim().startsWith('#')) continue;

    const indent = line.length - line.trimStart().length;

    // Top-level key (indent 0)
    if (indent === 0) {
      inScalarList = null;
      currentListItem = null;
      const colonIdx = line.indexOf(':');
      if (colonIdx === -1) {
        console.error(`parse-error: unexpected line at line ${lineNo + 1}: ${rawLine}`);
        exit(1);
      }
      const key = line.slice(0, colonIdx).trim();
      const rest = line.slice(colonIdx + 1).trim();

      topKey = key;

      if (rest === '') {
        // Start of a nested mapping or list — will be determined by next lines
        currentList = null;
        topMapping = null;
        result[key] = null; // placeholder, replaced when we see children
      } else {
        result[key] = parseScalar(rest);
        currentList = null;
        topMapping = null;
      }
      continue;
    }

    // List entry at indent 2 (top-level list items: `  - ...`)
    if (indent === 2 && line.trimStart().startsWith('- ')) {
      inScalarList = null;
      // Initialize the list if needed
      if (!Array.isArray(result[topKey])) {
        result[topKey] = [];
      }
      currentList = result[topKey];
      topMapping = null;

      // Parse the inline key-value after `- `
      const afterDash = line.trimStart().slice(2).trim();
      currentListItem = {};
      currentList.push(currentListItem);

      if (afterDash !== '') {
        const colonIdx = afterDash.indexOf(':');
        if (colonIdx !== -1) {
          const k = afterDash.slice(0, colonIdx).trim();
          const v = afterDash.slice(colonIdx + 1).trim();
          if (v !== '') {
            currentListItem[k] = parseScalar(v);
          } else {
            currentListItem[k] = null; // value on next line(s)
          }
        }
      }
      continue;
    }

    // Key-value inside list item (indent 4)
    if (indent === 4 && currentListItem !== null && !line.trimStart().startsWith('- ')) {
      const colonIdx = line.indexOf(':');
      if (colonIdx === -1) {
        console.error(`parse-error: unexpected line at line ${lineNo + 1}: ${rawLine}`);
        exit(1);
      }
      const k = line.slice(0, colonIdx).trim();
      const v = line.slice(colonIdx + 1).trim();

      if (v !== '') {
        currentListItem[k] = parseScalar(v);
        inScalarList = null;
      } else {
        // Start a sub-list (like expect_body_contains:)
        currentListItem[k] = [];
        inScalarList = { listRef: currentListItem[k] };
      }
      continue;
    }

    // Scalar list items inside list item entries (indent 6, or 4 with `- `)
    if (inScalarList !== null && line.trimStart().startsWith('- ')) {
      const val = line.trimStart().slice(2);
      inScalarList.listRef.push(parseScalar(val));
      continue;
    }

    // Key-value inside top-level mapping (indent 2, no leading dash)
    if (indent === 2 && currentList === null && !line.trimStart().startsWith('- ')) {
      // top-level mapping object (e.g., smoke_auth)
      if (topMapping === null) {
        topMapping = {};
        result[topKey] = topMapping;
      }
      const colonIdx = line.indexOf(':');
      if (colonIdx === -1) {
        console.error(`parse-error: unexpected line at line ${lineNo + 1}: ${rawLine}`);
        exit(1);
      }
      const k = line.slice(0, colonIdx).trim();
      const v = line.slice(colonIdx + 1).trim();
      topMapping[k] = parseScalar(v);
      continue;
    }

    // Fallthrough — unknown structure
    console.error(`parse-error: unrecognized YAML structure at line ${lineNo + 1}: ${rawLine}`);
    exit(1);
  }

  return result;
}

// ---------------------------------------------------------------------------
// Fetch helpers
// ---------------------------------------------------------------------------

async function fetchCheck(baseUrl, check, cookieHeader) {
  const url = baseUrl.replace(/\/$/, '') + check.path;
  const headers = {};
  if (cookieHeader) {
    headers['Cookie'] = cookieHeader;
  }

  let response;
  try {
    response = await fetch(url, {
      method: 'GET',
      headers,
      redirect: 'manual',
    });
  } catch (err) {
    return { pass: false, reason: `fetch error: ${err.message}` };
  }

  const status = response.status;

  // expect_status
  if (status !== check.expect_status) {
    return { pass: false, reason: `expected status ${check.expect_status}, got ${status}` };
  }

  // expect_location (for 3xx)
  if (check.expect_location !== undefined) {
    const location = response.headers.get('location') || '';
    if (location !== check.expect_location) {
      return { pass: false, reason: `expected Location: ${check.expect_location}, got: ${location}` };
    }
  }

  // Body assertions (only read body if needed)
  const needsBody =
    check.expect_body_contains !== undefined ||
    check.expect_body_not_contains !== undefined ||
    check.expect_link_href_pattern !== undefined;

  if (needsBody) {
    let body;
    try {
      body = await response.text();
    } catch (err) {
      return { pass: false, reason: `error reading body: ${err.message}` };
    }

    if (check.expect_body_contains !== undefined) {
      for (const expected of check.expect_body_contains) {
        if (!body.includes(expected)) {
          return { pass: false, reason: `expected body to contain: ${JSON.stringify(expected)}` };
        }
      }
    }

    if (check.expect_body_not_contains !== undefined) {
      for (const forbidden of check.expect_body_not_contains) {
        if (body.includes(forbidden)) {
          return { pass: false, reason: `expected body NOT to contain: ${JSON.stringify(forbidden)}` };
        }
      }
    }

    if (check.expect_link_href_pattern !== undefined) {
      const pattern = new RegExp(check.expect_link_href_pattern);
      const linkRegex = /<link[^>]+rel=["']stylesheet["'][^>]+href=["']([^"']+)["']/gi;
      let matched = false;
      let m;
      while ((m = linkRegex.exec(body)) !== null) {
        if (pattern.test(m[1])) {
          matched = true;
          break;
        }
      }
      if (!matched) {
        return {
          pass: false,
          reason: `no <link rel="stylesheet"> href matched pattern: ${check.expect_link_href_pattern}`,
        };
      }
    }
  }

  return { pass: true };
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

async function main() {
  const args = parseArgs(process.argv.slice(2));

  if (!args.taskSpec) {
    console.error('error: --task-spec <path> is required');
    exit(1);
  }

  // Apply --port override to base URL
  let baseUrl = args.baseUrl;
  if (args.port) {
    try {
      const parsed = new URL(baseUrl);
      parsed.port = args.port;
      baseUrl = parsed.toString().replace(/\/$/, '');
    } catch {
      baseUrl = `http://localhost:${args.port}`;
    }
  }

  // Read task spec
  let specContent;
  try {
    specContent = readFileSync(args.taskSpec, 'utf8');
  } catch (err) {
    console.error(`error: could not read task spec: ${err.message}`);
    exit(1);
  }

  // Extract YAML block
  const yamlBody = extractSmokeYamlBlock(specContent);
  if (!yamlBody) {
    console.error(`no smoke_checks found in ${args.taskSpec}`);
    exit(1);
  }

  // Parse YAML
  const parsed = parseMinimalYaml(yamlBody, args.taskSpec);

  if (!parsed.smoke_checks || !Array.isArray(parsed.smoke_checks) || parsed.smoke_checks.length === 0) {
    console.error(`no smoke_checks found in ${args.taskSpec}`);
    exit(1);
  }

  const smokeAuth = parsed.smoke_auth || null;

  let passed = 0;
  let failed = 0;
  const total = parsed.smoke_checks.length;

  for (const check of parsed.smoke_checks) {
    const path = check.path || '(unknown path)';

    // Resolve cookie header
    let cookieHeader = null;
    if (check.auth === 'signed-in' || check.auth === 'admin') {
      if (!smokeAuth || !smokeAuth.cookie_name || smokeAuth.cookie_value === undefined) {
        console.error(
          `smoke_auth required for auth: ${check.auth} but not declared in task spec`
        );
        exit(1);
      }
      cookieHeader = `${smokeAuth.cookie_name}=${smokeAuth.cookie_value}`;
    }

    const result = await fetchCheck(baseUrl, check, cookieHeader);

    if (result.pass) {
      console.log(`[PASS] ${path}`);
      passed++;
    } else {
      console.log(`[FAIL] ${path}: ${result.reason}`);
      failed++;
    }
  }

  console.log(`${passed} passed, ${failed} failed of ${total}`);
  exit(failed > 0 ? 1 : 0);
}

main().catch((err) => {
  console.error(`fatal: ${err.message}`);
  exit(1);
});
