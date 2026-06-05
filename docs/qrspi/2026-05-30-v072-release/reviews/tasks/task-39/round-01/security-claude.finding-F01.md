# F01 — Include-graph "billion laughs" DoS via unmemoized diamond expansion

**Severity:** High
**Category:** Input Validation / Denial of Service
**Location:** `tools/build-plugin.mjs:150–190` (`expand`)

## Finding

Cycle detection in `expand()` only checks the current ancestor `stack`
(`stack.includes(relPath)`, line 151) and does not memoize already-expanded
files. Each `!cat` directive triggers an independent re-expansion of the
target subtree. With repeated *non-cyclic* includes, the expansion is
exponential in the include depth — the classic "billion laughs" / XML-bomb
shape, which the cycle check does not catch because no path repeats inside
any single chain.

Concrete attacker-controlled fixtures (all valid under the strict grammar,
all lexically inside `$REPO_ROOT`, all distinct paths so the cycle stack
never fires):

```
skills/a0.md:
  !cat skills/a1.md
  !cat skills/a1.md

skills/a1.md:
  !cat skills/a2.md
  !cat skills/a2.md

… (28 more levels) …

skills/a29.md:
  payload line
```

`expand("skills/a0.md", [], ctx)` produces 2³⁰ ≈ 10⁹ copies of
`payload line`. The output is then handed to `fs.writeFileSync(dstAbs,
expanded)` (line 273) — a single multi-gigabyte string allocated in the
Node heap before being written.

## Attack scenario

1. Contributor opens a PR that adds the `a0.md` … `a29.md` fixtures under
   any shipped path (e.g. inside `skills/`, which is **not** in
   `STRIP_TOPLEVEL`).
2. CI's `bash32` job runs `node tools/build-plugin.mjs` (workflow line
   123), unconditionally and before any other gate.
3. Node either (a) OOM-aborts the GitHub-hosted runner (7 GB RAM, will
   blow well before 2³⁰ short lines fit in a single string heap object),
   (b) hangs until the 6-hour job timeout, or (c) fills the runner's
   ephemeral disk with the resulting `build/` write.
4. Because the gate is on every push to `qrspi/**` / `*/issue-*` and
   every PR to `main`, an attacker (or an honest mistake) can wedge CI
   for the whole release branch family, blocking other contributors.

A 20-deep diamond (~10⁶ expansions) fits in seconds and produces ~tens
of MB — small enough to slip past local "looks fine" review but large
enough to make every CI run write a junk `build/` and burn time.

## Why the existing guards don't catch it

- `stack.includes(relPath)` (line 151): catches `A → B → A` direct cycles.
  Diamond expansion never repeats a path *along a single chain*; the stack
  for the second `!cat a1` invocation is `[a0]`, not `[a0, a1]`.
- The strict regex / `RELPATH_TOKEN_RE` rejects nothing relevant.
- The outside-root guard on canonical paths is independent of fan-out.
- No depth limit. No total-byte limit on the accumulated `out` string.
- No visited-set memoization (which is the standard fix and would also
  let cycle detection survive without ancestor-stack scanning).

## Recommended fix

Add at least one of:

1. **Hard depth cap** (e.g. `if (stack.length > 64) throw …`) at the top
   of `expand()`. Cheap, sufficient to bound 2^depth blowup.
2. **Total expansion budget** — track `ctx.bytesEmitted` and abort with
   a fail-loud diagnostic above e.g. 32 MB. Catches wide-fanout shapes
   that stay shallow.
3. **Memoize expanded content per `relPath`** in `ctx.cache` once a file
   finishes expanding cleanly. Eliminates the exponential entirely; only
   safe because the resolver is pure (no variables/conditionals — see
   task-39 §Out).

Per task-39 §Definition of done the resolver must "fail non-zero with
file:line plus reason" — the depth/budget cap diagnostic should follow
the same shape (e.g. `<rel>:<line>: include depth limit (64) exceeded`)
so the audit trail is consistent with the other D3 conditions.
