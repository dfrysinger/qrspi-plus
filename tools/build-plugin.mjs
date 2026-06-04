#!/usr/bin/env node
// tools/build-plugin.mjs
// -----------------------------------------------------------------------------
// G32 plugin build pipeline (Task 39).
//
// Reads source repo at --root (default cwd), expands every `!cat <relpath>`
// directive in shipped .md files transitively from repo root, strips dev-only
// paths, and writes a reproducible plugin tree to --out (default <root>/build).
//
// Resolver grammar (D3, strict whole-line bare-relative form):
//   ^[[:space:]]*!cat[[:space:]]+<relpath>[[:space:]]*$
// where <relpath> is [A-Za-z0-9_./-]+, must NOT start with '/', must NOT
// contain a '..' segment, and after fs.realpathSync must remain inside
// canonical $REPO_ROOT/.
//
// Fail-loud (non-zero exit, file:line + reason on stderr) on every D3
// condition: malformed directive, missing target, include cycle (full cycle
// printed), absolute path, '..' traversal, outside-root include (mirrors
// T21's symlink-out-of-repo guard with the audit-friendly diagnostic
// `resolves outside repository`), and any `${CLAUDE_SKILL_DIR}` occurrence
// in shipped files.
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
// Strip rules. Top-level paths that are dev-only and MUST NOT ship.
//
// `docs/`, `tools/`, `tests/`, `reviews/` are explicit dev-only roots per
// task-39 §Definition of done. `build/` is the output sink and is skipped to
// prevent recursive copy. `.git*`, `.github/`, `.worktrees/`, `.vscode/`,
// `.claude/`, `STATUS.md`, `.qrspi-commit-msg.txt`, `.gitignore`, `.DS_Store`
// are repo metadata / dev-time scratch.
// ---------------------------------------------------------------------------
const STRIP_TOPLEVEL = new Set([
  'docs',
  'tools',
  'tests',
  'reviews',
  'build',
  '.git',
  '.github',
  '.worktrees',
  '.vscode',
  '.claude',
  'STATUS.md',
  'CONTRIBUTING.md',
  '.qrspi-commit-msg.txt',
  '.gitignore',
  '.DS_Store',
]);

// Inside `.claude-plugin/`, strip `marketplace.json`. Marketplace registry
// lives outside the plugin tree (its `source` field points at `./build`);
// shipping it inside `build/.claude-plugin/` would recursively self-reference.
function shouldStripRel(rel, entry, outRel) {
  // Skip the output directory itself if it lives inside root.
  if (outRel && (rel === outRel || rel.startsWith(outRel + path.sep))) {
    return true;
  }
  const segs = rel.split(path.sep);
  if (segs.length === 1 && STRIP_TOPLEVEL.has(segs[0])) return true;
  if (rel === path.join('.claude-plugin', 'marketplace.json')) return true;
  if (entry && entry.name === '.DS_Store') return true;
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

class BuildError extends Error {}

function makeContext(rootReal) {
  return { rootReal };
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
function expand(relPath, stack, ctx) {
  if (stack.includes(relPath)) {
    const cycle = [...stack, relPath].join(' -> ');
    throw new BuildError(`include cycle detected: ${cycle}`);
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
    } else {
      out += line + '\n';
    }
  }
  return out;
}

// Scan an expanded text body for the legacy `${CLAUDE_SKILL_DIR}` token.
function assertNoClaudeSkillDir(relPath, content) {
  const idx = content.indexOf(CLAUDE_SKILL_DIR_TOKEN);
  if (idx < 0) return;
  const before = content.slice(0, idx);
  const lineNo = before.split('\n').length;
  throw new BuildError(
    `${relPath}:${lineNo}: \${CLAUDE_SKILL_DIR} occurrence in shipped file (legacy form forbidden in v0.7.2 — convert to bare-relative !cat)`,
  );
}

// Outside-root guard for non-.md files. Mirrors T21's
// assert_path_under_repo_root shape with the same audit-friendly phrase.
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

// Recursive walk + emit.
function walk(rootReal, outDirAbs, outRelFromRoot, ctx) {
  function recurse(absDir, relDir) {
    const entries = fs.readdirSync(absDir, { withFileTypes: true });
    entries.sort((a, b) => (a.name < b.name ? -1 : a.name > b.name ? 1 : 0));
    for (const entry of entries) {
      const rel = relDir ? path.join(relDir, entry.name) : entry.name;
      if (shouldStripRel(rel, entry, outRelFromRoot)) continue;
      const srcAbs = path.join(absDir, entry.name);
      const dstAbs = path.join(outDirAbs, rel);
      let st;
      try {
        st = fs.statSync(srcAbs);
      } catch (e) {
        if (e && e.code === 'ENOENT') continue; // dangling symlink
        throw e;
      }
      if (st.isDirectory()) {
        fs.mkdirSync(dstAbs, { recursive: true });
        recurse(srcAbs, rel);
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
  recurse(rootReal, '');
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
  const outDirAbs = path.resolve(
    rootReal,
    args.out || path.join(rootReal, 'build'),
  );

  // Compute outDir relative to rootReal (if inside root) so the walker can
  // skip it during recursion.
  let outRelFromRoot = null;
  if (outDirAbs === rootReal || outDirAbs.startsWith(rootReal + path.sep)) {
    outRelFromRoot = path.relative(rootReal, outDirAbs);
    if (outRelFromRoot === '') outRelFromRoot = null;
  }

  // Wipe + recreate outDir for reproducibility.
  if (fs.existsSync(outDirAbs)) {
    fs.rmSync(outDirAbs, { recursive: true, force: true });
  }
  fs.mkdirSync(outDirAbs, { recursive: true });

  const ctx = makeContext(rootReal);

  try {
    walk(rootReal, outDirAbs, outRelFromRoot, ctx);
  } catch (e) {
    if (e instanceof BuildError) {
      process.stderr.write(`build-plugin: ${e.message}\n`);
      process.exit(1);
    }
    throw e;
  }
}

main();
