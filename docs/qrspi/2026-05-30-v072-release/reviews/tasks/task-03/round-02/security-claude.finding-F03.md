---
finding_id: R2-F03
severity: medium
change_type: correctness
referenced_files:
  - first-party-emission.md
  - SKILL.md
---

# F03 — reviewer_tag path traversal (medium · correctness)

**Location:** `first-party-emission.md` lines 70-76 (Path Rules); `SKILL.md` lines 43-46 (Reviewer Dispatch Contract, `reviewer_tag` parameter)

**Convergence:** Same gap as `security-codex.finding-F01.md` — reviewer_tag charset validation missing from path-rules contract. Same gap also flagged in T06 R1 sec-codex F03 (sidecar surface); T03 directly owns the path-rules surface so could close it here.

**Concrete attack scenario:**

1. Attacker with write access to `config.md` (or via a future dynamic-tag-derivation feature) supplies a traversal-bearing reviewer_tag: `../../.ssh/authorized_keys`.
2. First-party reviewer constructs Write path as `<round_subdir>/../../.ssh/authorized_keys.finding-F01.md` → normalizes to `~/.ssh/authorized_keys.finding-F01.md`.
3. Finding message body (which may contain attacker-quoted artifact content per rule 4) is written to traversal target. Crafted body could be a valid `authorized_keys` entry — RCE on the host.
4. Orchestrator reads round directory by glob; out-of-bounds write goes undetected.

**Scope of exposure (mitigations already in place):**
- Expected-Reviewer Matrix in SKILL.md hardcodes tag vocabulary (`quality-claude`, `security-claude`, etc.) — limits immediate risk.
- However, `first-party-emission.md` makes no mention of this invariant; future implementor reading the spec without the matrix would miss the gap.

**Proposed fix:** Add to `first-party-emission.md` § Path Rules: "`reviewer_tag` MUST match `^[a-z0-9-]+$` (lowercase alphanumeric + hyphen). Write call sites MUST validate this regex before path construction; tags failing the regex are a HARD-GATE refusal." This is in-scope for T03 R3 (small additive change to the path-rules contract that T03 owns).
