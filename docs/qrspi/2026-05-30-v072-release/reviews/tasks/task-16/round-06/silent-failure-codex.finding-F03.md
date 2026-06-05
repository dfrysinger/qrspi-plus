---
finding_id: R6-F03
reviewer_tag: silent-failure-codex
round: 6
severity: medium
change_type: correctness
referenced_files: [scripts/_resolve-lib.sh:74, scripts/_resolve-lib.sh:88, scripts/_resolve-lib.sh:131]
---

# silent-failure-codex F03 — `-f` existence vs `-r` readability mismatch

The CONFIG_MD / agent_file guards check `-f` (exists) but the resolve_model
diagnostic claims "unset or not a **readable** file" (L132). If CONFIG_MD exists
but is unreadable, `resolve_tier` misclassifies it (falls to Layer-4 with a
"config present but no default_tier" cause) and `resolve_model` can emit the
"unconfigured tier" diagnostic instead of a config-path error. `2>/dev/null` on
the greps suppresses the underlying read error.

**Impact:** a real permission/I-O failure on the config path is masked as a
normal fallback or an unconfigured-tier error — misleading the operator's repair
path.

**Fix:** change the existence checks to readability checks (`-r`) at L74
(agent_file), L88 (CONFIG_MD in resolve_tier), L131 (CONFIG_MD in resolve_model)
so the diagnostics are truthful, plus a present-but-unreadable behavioral test.

Convergent with code-quality-codex.finding-F01 (cross-reviewer hit, same root
cause). Chat-only return persisted by orchestrator.
