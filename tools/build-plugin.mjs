#!/usr/bin/env node
// tools/build-plugin.mjs
// -----------------------------------------------------------------------------
// Plugin build pipeline.
//
// Reads source repo at --root (default cwd), expands every `!cat <relpath>`
// directive in shipped .md files transitively from repo root, ships only an
// explicit manifest of runtime content, and writes a reproducible plugin tree
// to --out (default <root>/build).
//
// Resolver grammar (D3, strict whole-line bare-relative form):
//   ^[[:space:]]*!cat[[:space:]]+<relpath>[[:space:]]*$
// where <relpath> is [A-Za-z0-9_./-]+, must NOT start with '/', must NOT
// contain a '..' segment, and after fs.realpathSync must remain inside
// canonical $REPO_ROOT/.
//
// Fail-loud (non-zero exit, file:line + reason on stderr) on every D3
// condition: malformed directive, missing target, include cycle (full cycle
// printed), absolute path, '..' traversal, outside-root include (mirrors the
// symlink-out-of-repo guard with the audit-friendly diagnostic
// `resolves outside repository`), include depth-cap exceeded, and any
// `${CLAUDE_SKILL_DIR}` occurrence in shipped files (.md OR non-.md).
//
// Stdlib only (no third-party dependencies).

import fs from 'node:fs';
import path from 'node:path';
import process from 'node:process';

// ---------------------------------------------------------------------------
// CLI argument parsing.
// ---------------------------------------------------------------------------
function parseArgs(argv) {
  const args = { root: process.cwd(), out: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--root') args.root = argv[++i];
    else if (a === '--out') args.out = argv[++i];
    else if (a === '--help' || a === '-h') {
      process.stdout.write(
        'usage: node tools/build-plugin.mjs [--root <dir>] [--out <dir>]\n',
      );
      process.exit(0);
    } else {
      process.stderr.write(`build-plugin: unknown argument: ${a}\n`);
      process.exit(2);
    }
  }
  return args;
}

// ---------------------------------------------------------------------------
// Manifest of shippable content (what to copy into build/).
//
// This is an explicit allowlist rather than a walk-and-subtract: anything not
// listed here is implicitly excluded, eliminating accidental leaks of
// dotenv/backup/credential files that happen to live in a contributor's
// worktree.
//
// `dirs`  — directory subtrees copied recursively (each entry optional unless
//           tagged `required: true`). Each subtree is filtered through the
//           denylist below.
// `files` — top-level files copied verbatim if present.
// ---------------------------------------------------------------------------
const MANIFEST_DIRS = [
  { rel: 'skills', required: true },
  { rel: 'agents', required: false },
  { rel: 'scripts', required: false },
  { rel: 'templates', required: false },
  { rel: '.claude-plugin', required: true },
];

const MANIFEST_FILES = [
  { rel: 'LICENSE', required: true },
  { rel: 'README.md', required: true },
  { rel: 'AGENTS.md', required: false },
  { rel: 'CLAUDE.md', required: false },
  { rel: 'PROVENANCE.md', required: false },
];

// Inside `.claude-plugin/`, marketplace.json is the registry that points AT
// `./build`; shipping it inside `build/.claude-plugin/` would self-reference.
const MANIFEST_PATH_EXCLUSIONS = new Set([
  path.join('.claude-plugin', 'marketplace.json'),
]);

// Defense-in-depth denylist: refuse (fail-loud) any walked file whose basename
// matches a secret/backup pattern, even if the file lives under a manifest
// directory. Catches the "contributor accidentally checks in `.env` under
// scripts/" mistake path that the manifest alone wouldn't stop.
const SECRET_BASENAME_PATTERNS = [
  /^\.env(\..+)?$/i,
  /^\.envrc$/i,
  /^\.npmrc$/i,
  /^\.netrc$/i,
  /^id_(rsa|dsa|ecdsa|ed25519)(\.pub)?$/i,
  /^credentials(\..+)?$/i,
  /\.(pem|key|p12|pfx)$/i,
  /\.(bak|orig|rej|swp|swo)$/i,
  /~$/,
];

function isSecretBasename(name) {
  for (const re of SECRET_BASENAME_PATTERNS) {
    if (re.test(name)) return true;
  }
  return false;
}

// ---------------------------------------------------------------------------
// Resolver: strict whole-line bare-relative !cat grammar.
// Two regexes — the broad `^\s*!cat\b` detector lets us flag malformed
// directives (extra args, embedded characters outside the grammar) at
// file:line, and the strict regex captures the relpath when the line is
// well-formed.
// ---------------------------------------------------------------------------
const CAT_DETECT_RE = /^[ \t]*!cat\b/;
const CAT_STRICT_RE = /^[ \t]*!cat[ \t]+([A-Za-z0-9_./-]+)[ \t]*$/;
const RELPATH_TOKEN_RE = /^[A-Za-z0-9_./-]+$/;
const CLAUDE_SKILL_DIR_TOKEN = '${CLAUDE_SKILL_DIR}';

// Hard cap on `!cat` include nesting. Defends against billion-laughs-style
// diamond DoS (cycle-stack alone catches direct ancestor cycles, not
// non-cyclic deep nesting). 8 is comfortably above any legitimate fan-in
// observed in v0.7.2 source (deepest legitimate chain is well under 8);
// it acts as a structural backstop alongside the per-entry byte cap.
const MAX_INCLUDE_DEPTH = 8;

// Per-cache-entry materialized-output cap. Defends against intra-file
// fan-out blow-up that the depth cap alone does not bound: a file with N
// `!cat <child>` directives caches an expansion of size N×|expand(child)|,
// so depth-D fan-out reaches N^D × |leaf| in worst case. 4 MB is far
// above any legitimate single-skill expansion (largest extant skill bodies
// are tens of KB). Primary defense against materialized-size DoS.
const MAX_EXPAND_BYTES = 4 * 1024 * 1024;

class BuildError extends Error {}

function makeContext(rootReal) {
  return { rootReal, expandCache: new Map() };
}

// Resolve a target relpath to its canonical absolute path inside the root.
// Throws fail-loud diagnostics with the supplied `<file>:<line>:` prefix.
function resolveTarget(target, sourceRel, lineNo, ctx) {
  if (target.startsWith('/')) {
    throw new BuildError(
      `${sourceRel}:${lineNo}: absolute paths not allowed in !cat directive: ${target}`,
    );
  }
  if (target.split('/').includes('..')) {
    throw new BuildError(
      `${sourceRel}:${lineNo}: outside-root traversal not allowed in !cat (invalid '..' segment): ${target}`,
    );
  }
  const lexicalAbs = path.join(ctx.rootReal, target);
  let canonical;
  try {
    canonical = fs.realpathSync(lexicalAbs);
  } catch (e) {
    if (e && e.code === 'ENOENT') {
      throw new BuildError(
        `${sourceRel}:${lineNo}: target not found: ${target}`,
      );
    }
    throw e;
  }
  if (
    canonical !== ctx.rootReal &&
    !canonical.startsWith(ctx.rootReal + path.sep)
  ) {
    throw new BuildError(
      `${sourceRel}:${lineNo}: ${target} resolves outside repository (canonical: ${canonical})`,
    );
  }
  return canonical;
}

// Expand a file's content transitively. `relPath` is the bare-relative path
// from rootReal (forward-slash form, matching the directive grammar).
// `stack` is the cycle-detection stack of relPaths currently being expanded.
//
// Memoization (`ctx.expandCache`) makes diamond fan-in cheap and prevents
// billion-laughs blow-up in well-formed include graphs; the depth cap
// (`MAX_INCLUDE_DEPTH`) is the structural backstop. Cycle detection runs
// BEFORE the cache check — the cache is only populated after a file's
// expansion completes, so a re-entry while the same file is on the stack is
// always a true cycle.
function expand(relPath, stack, ctx) {
  if (stack.includes(relPath)) {
    const cycle = [...stack, relPath].join(' -> ');
    throw new BuildError(`include cycle detected: ${cycle}`);
  }
  if (stack.length >= MAX_INCLUDE_DEPTH) {
    const chain = [...stack, relPath].join(' -> ');
    throw new BuildError(
      `include depth cap exceeded (max ${MAX_INCLUDE_DEPTH}, deep nesting refused): ${chain}`,
    );
  }
  if (ctx.expandCache.has(relPath)) {
    return ctx.expandCache.get(relPath);
  }
  const absPath = path.join(ctx.rootReal, relPath);
  const raw = fs.readFileSync(absPath, 'utf8').replace(/\r/g, '');
  const lines = raw.split('\n');
  let out = '';
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const isLastEmpty = i === lines.length - 1 && line === '';
    if (isLastEmpty) {
      // Trailing element from the file's terminating newline; the prior
      // line's appended '\n' already carries it.
      continue;
    }
    const lineNo = i + 1;
    if (CAT_DETECT_RE.test(line)) {
      const m = CAT_STRICT_RE.exec(line);
      if (!m) {
        throw new BuildError(
          `${relPath}:${lineNo}: malformed !cat directive (strict grammar requires '^\\s*!cat <relpath>\\s*$'): ${line}`,
        );
      }
      const target = m[1];
      if (!RELPATH_TOKEN_RE.test(target)) {
        throw new BuildError(
          `${relPath}:${lineNo}: invalid !cat relpath token: ${target}`,
        );
      }
      // Outside-root / abs / .. / missing checks.
      resolveTarget(target, relPath, lineNo, ctx);
      const expandedChild = expand(target, [...stack, relPath], ctx);
      out += expandedChild;
      if (out.length > MAX_EXPAND_BYTES) {
        const chain = [...stack, relPath].join(' -> ');
        throw new BuildError(
          `${relPath}:${lineNo}: include expansion size cap exceeded ` +
            `(max ${MAX_EXPAND_BYTES} bytes per file; got ${out.length}); ` +
            `chain: ${chain}`,
        );
      }
    } else {
      out += line + '\n';
    }
  }
  ctx.expandCache.set(relPath, out);
  return out;
}

// Scan a text body for the legacy `${CLAUDE_SKILL_DIR}` token. Used both for
// expanded .md output and for shipped non-.md files (post-copy pass).
function assertNoClaudeSkillDir(relPath, content) {
  const idx = content.indexOf(CLAUDE_SKILL_DIR_TOKEN);
  if (idx < 0) return;
  const before = content.slice(0, idx);
  const lineNo = before.split('\n').length;
  throw new BuildError(
    `${relPath}:${lineNo}: \${CLAUDE_SKILL_DIR} occurrence in shipped file (legacy form forbidden in v0.7.2 — convert to bare-relative !cat)`,
  );
}

// Copy a non-.md file from source → dest with mode preservation, after
// canonicalizing to refuse symlink-escape (mirrors the symlink-out-of-repo
// guard with the same audit-friendly diagnostic phrase).
function copyFilePreservingMode(srcAbs, dstAbs, ctx, relPath) {
  let canonical;
  try {
    canonical = fs.realpathSync(srcAbs);
  } catch (e) {
    if (e && e.code === 'ENOENT') {
      throw new BuildError(`${relPath}: target not found`);
    }
    throw e;
  }
  if (
    canonical !== ctx.rootReal &&
    !canonical.startsWith(ctx.rootReal + path.sep)
  ) {
    throw new BuildError(
      `${relPath}: resolves outside repository (canonical: ${canonical})`,
    );
  }
  fs.copyFileSync(canonical, dstAbs);
  fs.chmodSync(dstAbs, fs.statSync(canonical).mode);
}

// ---------------------------------------------------------------------------
// Manifest-driven copy. Each manifest dir is recursively walked from the
// source root; each manifest file is copied if present. A file is shipped
// only if:
//
//   1. It descends from a manifest entry (or IS one, for top-level files).
//   2. Its basename does NOT match a SECRET_BASENAME_PATTERN (denylist).
//   3. Its relative path is not in MANIFEST_PATH_EXCLUSIONS.
//
// Each shipped file goes through the same realpath/outside-root canonical-
// ization. .md files are expanded through the !cat resolver; non-.md files
// are byte-copied and then scanned for the legacy `${CLAUDE_SKILL_DIR}`
// token.
// ---------------------------------------------------------------------------
function recurseDir(absDir, relDir, outDirAbs, ctx) {
  let entries;
  try {
    entries = fs.readdirSync(absDir, { withFileTypes: true });
  } catch (e) {
    if (e && e.code === 'ENOENT') {
      throw new BuildError(`${relDir}: directory not found during walk`);
    }
    throw e;
  }
  entries.sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0));
  for (const entry of entries) {
    const rel = relDir ? path.join(relDir, entry.name) : entry.name;
    if (MANIFEST_PATH_EXCLUSIONS.has(rel)) continue;
    if (isSecretBasename(entry.name)) {
      throw new BuildError(
        `${rel}: refused — basename matches secret/backup denylist (.env / *.pem / *.key / id_rsa / *.bak / *~ / *.swp / etc.)`,
      );
    }
    const srcAbs = path.join(absDir, entry.name);
    const dstAbs = path.join(outDirAbs, rel);
    let st;
    try {
      // lstat-then-stat would let us distinguish dangling symlinks; we use
      // statSync (follows symlinks) and surface ENOENT as fail-loud instead
      // of silently swallowing it — consistent with the rest of the
      // resolver's posture.
      st = fs.statSync(srcAbs);
    } catch (e) {
      if (e && e.code === 'ENOENT') {
        throw new BuildError(
          `${rel}: target not found during walk (broken symlink or removed mid-build)`,
        );
      }
      throw e;
    }
    if (st.isDirectory()) {
      fs.mkdirSync(dstAbs, { recursive: true });
      recurseDir(srcAbs, rel, outDirAbs, ctx);
    } else if (st.isFile()) {
      fs.mkdirSync(path.dirname(dstAbs), { recursive: true });
      if (entry.name.endsWith('.md')) {
        // Pre-flight outside-root check on the .md source — catches a
        // SKILL.md that is itself a symlink whose canonical target
        // escapes rootReal (the symlink-escape regression fixture).
        let canonical;
        try {
          canonical = fs.realpathSync(srcAbs);
        } catch (e) {
          if (e && e.code === 'ENOENT') {
            throw new BuildError(`${rel}: target not found`);
          }
          throw e;
        }
        if (
          canonical !== ctx.rootReal &&
          !canonical.startsWith(ctx.rootReal + path.sep)
        ) {
          throw new BuildError(
            `${rel}: resolves outside repository (canonical: ${canonical})`,
          );
        }
        const relForward = rel.split(path.sep).join('/');
        const expanded = expand(relForward, [], ctx);
        assertNoClaudeSkillDir(relForward, expanded);
        fs.writeFileSync(dstAbs, expanded);
      } else {
        copyFilePreservingMode(srcAbs, dstAbs, ctx, rel);
      }
    }
  }
}

function copyManifest(rootReal, outDirAbs, ctx) {
  for (const dir of MANIFEST_DIRS) {
    const absDir = path.join(rootReal, dir.rel);
    let st;
    try {
      st = fs.statSync(absDir);
    } catch (e) {
      if (e && e.code === 'ENOENT') {
        if (dir.required) {
          throw new BuildError(
            `manifest: required directory missing from source root: ${dir.rel}`,
          );
        }
        continue;
      }
      throw e;
    }
    if (!st.isDirectory()) {
      throw new BuildError(
        `manifest: expected directory at ${dir.rel}, found non-directory`,
      );
    }
    fs.mkdirSync(path.join(outDirAbs, dir.rel), { recursive: true });
    recurseDir(absDir, dir.rel, outDirAbs, ctx);
  }
  for (const file of MANIFEST_FILES) {
    const absFile = path.join(rootReal, file.rel);
    let st;
    try {
      st = fs.statSync(absFile);
    } catch (e) {
      if (e && e.code === 'ENOENT') {
        if (file.required) {
          throw new BuildError(
            `manifest: required file missing from source root: ${file.rel}`,
          );
        }
        continue;
      }
      throw e;
    }
    if (!st.isFile()) {
      throw new BuildError(
        `manifest: expected regular file at ${file.rel}, found non-file`,
      );
    }
    if (isSecretBasename(file.rel)) {
      throw new BuildError(
        `${file.rel}: refused — basename matches secret/backup denylist`,
      );
    }
    const dstAbs = path.join(outDirAbs, file.rel);
    fs.mkdirSync(path.dirname(dstAbs), { recursive: true });
    if (file.rel.endsWith('.md')) {
      const expanded = expand(file.rel, [], ctx);
      assertNoClaudeSkillDir(file.rel, expanded);
      fs.writeFileSync(dstAbs, expanded);
    } else {
      copyFilePreservingMode(absFile, dstAbs, ctx, file.rel);
    }
  }
}

// Final pass: walk the assembled build/ tree and assert no shipped file
// (.md or non-.md) contains a literal `${CLAUDE_SKILL_DIR}` token. The .md
// path is also scanned during expansion above; this pass catches the
// non-.md path that the per-file scan would otherwise skip (shell scripts,
// JSON manifests, templates).
function assertBuildTreeFreeOfLegacyToken(buildDirAbs) {
  function walk(absDir, relDir) {
    const entries = fs.readdirSync(absDir, { withFileTypes: true });
    for (const entry of entries) {
      const rel = relDir ? path.join(relDir, entry.name) : entry.name;
      const abs = path.join(absDir, entry.name);
      if (entry.isDirectory()) {
        walk(abs, rel);
      } else if (entry.isFile()) {
        // utf8 read of binary content yields garbled but non-throwing
        // output; a literal-token indexOf against it is harmless.
        const content = fs.readFileSync(abs, 'utf8');
        assertNoClaudeSkillDir(rel.split(path.sep).join('/'), content);
      }
    }
  }
  walk(buildDirAbs, '');
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  let rootReal;
  try {
    rootReal = fs.realpathSync(args.root);
  } catch (e) {
    process.stderr.write(`build-plugin: --root not found: ${args.root}\n`);
    process.exit(2);
  }

  // -------------------------------------------------------------------------
  // VERSION authoring path (T28 / G8). The repo-root `VERSION` file is the
  // sole authoring source for the plugin version. Read it, validate the
  // structural invariant (single non-empty line — ignoring at most one
  // trailing newline), then stamp the value into the five consumer manifests
  // before the build copy walks `.claude-plugin/`.
  //
  // Per design.md § Dependencies + edge cases bullet 1, this script does NOT
  // parse or validate semver — it reads the line and writes it through.
  // Stricter validation is deferred.
  // -------------------------------------------------------------------------
  const VERSION_DIAG_PREFIX =
    'version-source-missing-or-malformed: VERSION at repo root must contain a single non-empty version string';
  const versionPath = path.join(rootReal, 'VERSION');
  let versionRaw;
  try {
    versionRaw = fs.readFileSync(versionPath, 'utf8');
  } catch (e) {
    process.stderr.write(`build-plugin: ${VERSION_DIAG_PREFIX} (read: ${e.code || e.message})\n`);
    process.exit(1);
  }
  // Normalize CRLF and strip exactly one trailing newline. Anything left
  // containing a newline is multi-line input — reject.
  const versionNorm = versionRaw.replace(/\r/g, '').replace(/\n$/, '');
  if (versionNorm.length === 0 || versionNorm.includes('\n') || versionNorm.trim().length === 0) {
    process.stderr.write(`build-plugin: ${VERSION_DIAG_PREFIX}\n`);
    process.exit(1);
  }
  const versionValue = versionNorm.trim();

  // Stamp the four source manifests in-place. The fifth consumer
  // (build/.claude-plugin/plugin.json) is produced by the manifest copy
  // below, which inherits the just-stamped .claude-plugin/plugin.json.
  // Each manifest declares its own JSON shape via a writer callback — the
  // script does not assume a flat top-level `version` field.
  const consumerStamps = [
    {
      rel: '.claude-plugin/plugin.json',
      stamp: (obj) => { obj.version = versionValue; },
    },
    {
      rel: '.claude-plugin/marketplace.json',
      stamp: (obj) => {
        if (Array.isArray(obj.plugins)) {
          for (const p of obj.plugins) p.version = versionValue;
        }
      },
    },
    {
      rel: '.github/plugin/plugin.json',
      stamp: (obj) => { obj.version = versionValue; },
    },
    {
      rel: '.github/plugin/marketplace.json',
      stamp: (obj) => {
        if (obj.metadata) obj.metadata.version = versionValue;
        if (Array.isArray(obj.plugins)) {
          for (const p of obj.plugins) p.version = versionValue;
        }
      },
    },
  ];
  for (const { rel, stamp } of consumerStamps) {
    const abs = path.join(rootReal, rel);
    let raw;
    try {
      raw = fs.readFileSync(abs, 'utf8');
    } catch (e) {
      process.stderr.write(
        `build-plugin: consumer manifest missing or unreadable: ${rel} (${e.code || e.message})\n`,
      );
      process.exit(1);
    }
    let obj;
    try {
      obj = JSON.parse(raw);
    } catch (e) {
      process.stderr.write(`build-plugin: consumer manifest malformed JSON: ${rel} (${e.message})\n`);
      process.exit(1);
    }
    stamp(obj);
    // Preserve 2-space indent + trailing newline (the canonical form of the
    // four checked-in consumer files).
    fs.writeFileSync(abs, JSON.stringify(obj, null, 2) + '\n');
  }

  // Resolve --out lexically (target may not exist yet). Default is
  // <rootReal>/build. path.resolve here treats relative --out as relative to
  // rootReal, matching CLI conventions.
  const outDirLex = path.resolve(
    rootReal,
    args.out || path.join(rootReal, 'build'),
  );
  // Canonicalize the parent so symlink-bearing paths (e.g. /tmp →
  // /private/tmp on macOS) compare correctly against rootReal in the guard
  // below. The target itself may not exist yet; realpath the existing
  // ancestor and re-attach the trailing tail.
  function canonicalizeMaybeMissing(p) {
    let cur = p;
    const tail = [];
    // Walk up until an existing prefix is found.
    // Bound by sane filesystem depth; rootReal is itself realpath'd so any
    // existing ancestor will be canonical.
    // eslint-disable-next-line no-constant-condition
    while (true) {
      try {
        const real = fs.realpathSync(cur);
        return tail.length ? path.join(real, ...tail.reverse()) : real;
      } catch (e) {
        if (!e || e.code !== 'ENOENT') throw e;
        const parent = path.dirname(cur);
        if (parent === cur) {
          // Hit filesystem root without finding any existing ancestor.
          return p;
        }
        tail.push(path.basename(cur));
        cur = parent;
      }
    }
  }
  const outDirAbs = canonicalizeMaybeMissing(outDirLex);

  // Hard-stop guard BEFORE any rmSync: --out must NOT be the repository
  // root itself, nor any ancestor of the root. Otherwise the wipe step
  // (`fs.rmSync(outDirAbs, {recursive:true, force:true})`) would erase the
  // working tree (including .git) and `force:true` would silence the error.
  if (outDirAbs === rootReal) {
    process.stderr.write(
      `build-plugin: --out cannot equal the repository root (would wipe source): ${outDirAbs}\n`,
    );
    process.exit(1);
  }
  if (rootReal.startsWith(outDirAbs + path.sep)) {
    process.stderr.write(
      `build-plugin: --out is an ancestor of the repository root (would wipe source): ${outDirAbs}\n`,
    );
    process.exit(1);
  }

  // Wipe + recreate outDir for reproducibility. Safe now: the guard above
  // has already rejected any --out that could destroy the source tree.
  if (fs.existsSync(outDirAbs)) {
    fs.rmSync(outDirAbs, { recursive: true, force: true });
  }
  fs.mkdirSync(outDirAbs, { recursive: true });

  const ctx = makeContext(rootReal);

  try {
    copyManifest(rootReal, outDirAbs, ctx);
    assertBuildTreeFreeOfLegacyToken(outDirAbs);
  } catch (e) {
    if (e instanceof BuildError) {
      process.stderr.write(`build-plugin: ${e.message}\n`);
      process.exit(1);
    }
    throw e;
  }
}

main();
