---
finding_id: R3-F03
severity: low
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L1026]
artifact: plan
round: 3
reviewer: security-claude
---

T33's `--report-out` path-validation check uses a string-prefix match (`"under docs/qrspi/"`) without requiring path normalization, allowing a `..`-traversal bypass against the prefix check while remaining syntactically "inside" `docs/qrspi/`.

**What the spec says today.** T33's test expectation (plan.md L1026) states: "When `--report-out` names a path outside the declared spike-deliverable location under `docs/qrspi/`, the script exits 1 with a named path-validation diagnostic before attempting any dispatch or report write."

**The gap.** The check as written is a policy declaration without a normalization requirement. A path like `docs/qrspi/../../../etc/shadow` passes the string-prefix test (`startsWith("docs/qrspi/")` is true for this literal string) but resolves to `/etc/shadow` after normalization. Without an explicit requirement to normalize the path before the prefix check, an implementation that does a string-based prefix match — which is the natural implementation in bash shell scripting — would allow traversal to any world-readable file via the `--report-out` argument.

This is relevant because `scripts/g4-cache-probe.sh` is a shell script that will implement this check in bash (per the bash 3.2 portability requirement). Bash string comparison does not normalize paths automatically; the implementer must explicitly call `realpath` or equivalent before checking the prefix.

**Fix.** Add to T33's test expectation: "Before applying the path-validation check, the script resolves the `--report-out` value to its canonical absolute path (e.g., via `realpath` or equivalent) and applies the prefix check against the resolved path, not the raw argument string. A path that cannot be resolved (parent directory does not exist) exits 1 with a named path-validation diagnostic." The T33 behavioral expectations should also include a fixture with a `..`-traversal `--report-out` argument and assert it exits 1 with the path-validation diagnostic.
