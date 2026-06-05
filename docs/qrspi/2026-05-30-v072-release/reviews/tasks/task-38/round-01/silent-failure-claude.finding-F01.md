# F01 — Silent failure on `!cat` expansion of altitude-boundary file

**Severity:** high
**Category:** Missing error path / silent fallback
**File:** `agents/qrspi-structure-scope-reviewer.md:20`

The `!cat skills/_shared/structure-altitude-boundary.md` is a passive include with no fallback. If T37 hasn't deployed the file or the orchestrator does not expand `!cat`, the boundary vocabulary silently disappears from reviewer context — reviewer keeps emitting authoritative-looking findings without altitude precision.

**Recommended fix:** convert to active `Read skills/_shared/structure-altitude-boundary.md` (matching the existing `Read skills/structure/owns-defers.md` pattern), or add a halt-on-empty verification.
