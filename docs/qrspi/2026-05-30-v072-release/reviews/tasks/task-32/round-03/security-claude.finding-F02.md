# F02 — Design finalize re-reads user-authored goals.md without untrusted-data guard

**Severity:** medium
**Category:** Prompt injection / missing untrusted-data wrapper
**File:** `skills/design/SKILL.md:277`

Design finalize loads `goals.md` to validate every goal has a corresponding 5-field block. User-authored "What we know so far" prose enters context unwrapped on every normal finalize (not just compaction). Same mitigation as F01.

**Required fix:** Apply structural-tokens-only enumeration pattern to the finalize read of goals.md.
