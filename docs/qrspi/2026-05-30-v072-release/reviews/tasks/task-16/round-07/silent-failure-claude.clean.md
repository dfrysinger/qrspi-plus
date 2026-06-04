# Silent Failure Hunter — task-16 round-07 (fix-cycle 6) — CLEAN

Scope: fix-6 increment only (empty-value HALT guard in `resolve_model`;
`-f`→`-r` readability checks at 3 sites; extracted `_halt_unconfigured_tier`
helper). No newly-introduced silent-failure or regression found.

## (a) `_halt_unconfigured_tier` returns non-zero; both callers still HALT — OK
The helper (`_resolve-lib.sh:55-59`) ends with `return 1`. Both callsites invoke
it *directly* (not inside `$(...)`, a pipe, or a subshell):
- absent-row branch — `:154-157`: `_halt_unconfigured_tier "$tier"` then an
  explicit `return 1` on the next line.
- explicit-`none` branch — `:180-183`: same direct call + explicit `return 1`.
The exit code is doubly guaranteed: even if the helper's own `return 1` were
lost, each caller follows with its own unconditional `return 1`. No command
substitution captures and discards the status. Both paths HALT non-zero.

## (b) Empty-value guard placement — OK
The guard (`:172-176`) sits AFTER key-strip + `_normalize_tier_value` (`:163-165`)
and BEFORE the none-check (`:180-183`):
- It cannot be bypassed: the same normalized `$value` that the none-check and the
  success emit consume is the value tested for emptiness; an inline-comment-only
  or trailing-whitespace-only row normalizes to empty and is caught here.
- It does not break the none-check: `none` is non-empty, so `[ -z "$value" ]` is
  false and control reaches `[ "$value" = "none" ]`.
- It does not break the real-row emit: a populated value passes both guards and
  reaches the `printf` at `:186`.

## (c) `-f`→`-r` at 3 sites — no new silent fallthrough
- `:85` agent_file, `:99` CONFIG_MD (Layer 3), `:142` CONFIG_MD (resolve_model).
- Readable-but-empty file: `-r` true → `grep` matches nothing → empty result →
  routed into the existing empty/absent HALT or Layer-3→Layer-4 fall-through,
  identical to the prior `-f` behavior. No silent success.
- Unreadable-but-present file: `-r` now false → Layer-3 `config_present=0` warn
  path / resolve_model CONFIG_MD HALT (`:142-145`). This is *stricter* than the
  old `-f` (which treated an unreadable file as present and then silently
  grep-failed); the change closes a gap rather than opening one. No regression.
- Directory at CONFIG_MD: `-r` true, but `grep` on a directory emits nothing
  (stderr suppressed) → unconfigured/empty HALT. Still halts.

Deferred/adjudicated items (D4 duplicate-tier-row, internal-whitespace-collapse,
Layer-4 medium warn+exit0, 4 pre-existing bats failures) intentionally not
re-raised.

Verdict: PASS — no blocking findings in the fix-6 delta.
