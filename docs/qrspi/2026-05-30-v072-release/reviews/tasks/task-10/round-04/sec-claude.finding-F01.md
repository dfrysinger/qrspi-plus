---
finding_id: R4-F01
severity: medium
change_type: correctness
referenced_files: [agents/qrspi-finding-verifier.md]
---

# Field-ordering invariant rationale is logically inverted for stated "last value wins" threat

**Location:** `agents/qrspi-finding-verifier.md` ~L124 (diff +39): "pyyaml-style 'last value wins' parsers would let a malformed defect_class: value containing an injected score: on a subsequent line silently override real values that came earlier. Putting defect_class: last bounds the blast radius..."

**Critique:** Under LVW semantics, a key appearing LATER wins over the same key appearing EARLIER. If `defect_class:` is LAST and its value contains an injected `score: 0` line, the injection would land at the END of the file where it WINS under LVW. Putting `defect_class:` last makes the stated LVW threat WORSE, not better.

**What the ordering actually protects against:** today's `verifier-fan-in.sh` uses `awk '/^score:/ {print $2; exit}'` — a "first value wins" (FVW) pattern. Ordering is protective for FVW parsers, not LVW parsers. The REAL protection against injection through `defect_class:` is the shape constraint `^[a-z0-9][a-z0-9-]*$`, which forbids newlines/colons/spaces regardless of position.

**Concrete attack scenario:** future developer adds pyyaml.safe_load() (LVW), reads documentation, concludes "ordering protects me — don't need to validate defect_class values." Later, shape constraint is relaxed for richer classification. Compromised verifier writes defect_class: value containing newline+score: 0. pyyaml reads injected score (last occurrence) instead of real.

**Note:** sec-codex returned CLEAN — disagreement between security reviewers. Conceptually valid critique, bounded practical impact (shape constraint prevents injection today), but documentation creates false confidence for future LVW adopters.

**Recommended fix:** rewrite the rationale to credit the shape constraint as primary defense, and frame field-ordering as defense-in-depth for FVW parsers specifically. Add explicit warning: "Future parsers using last-value-wins semantics MUST validate defect_class: values against the shape regex before consuming the sidecar — field ordering does NOT protect against LVW injection."
