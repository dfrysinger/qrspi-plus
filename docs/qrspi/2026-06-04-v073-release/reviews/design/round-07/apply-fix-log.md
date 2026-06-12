# R07 apply-fix log

**Kept (3):**
- quality-codex.F01 (80): CD-1 path-format contradiction (L13 said "absolute-path" but L21 specifies repo-relative + step-relative joined against `<abs_path>`). **Applied** — L13 rewritten to match L21's spec.
- quality-claude.F02 (70): CD-2 generation table omitted "plan" step despite G3 change 3 requiring `absorption_map_path` at the plan step. **Applied** — CD-2 generation table extended with Plan branch; G3 acceptance bullet adds bats fixture for `--step plan`.
- scope-codex.F01 (35): recurring blanket boundary-drift critique without quoted prose. **Deferred** — same disposition as R03-R06; scope-claude clean-endorsed R07; already partially addressed at G9 Pass 1 preamble (R06).

**Dropped (4) by verifier thresholds:**
- quality-claude.F01 (15) — Mermaid hallucination
- quality-codex.F02 (10), F03 (20), F04 (0) — TestStrategy / research-citation hallucinations
