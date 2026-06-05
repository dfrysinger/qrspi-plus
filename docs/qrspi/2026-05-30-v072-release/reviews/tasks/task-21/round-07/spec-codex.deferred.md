---
finding_ids: [F01, F02]
disposition: DEFER (accept-with-issues → v0.7.3)
---

# Spec-codex R7 findings — DEFER

F01 (LOW scope): "Over-implementation" — batch --agents tag allowlist, skill-path boundary, batch job_id validation, companion tag+round_dir record validation. These extensions close adjacent path-exfil attack surfaces in the same dispatch surface family. Reverting would weaken the v0.7.2 security story with no offsetting benefit. Recommendation: retroactively widen task-21 spec scope in v0.7.3 to formally include these surfaces.

F02 (LOW advisory): scripts/lib/path-guard.sh added _qrspi_canonicalize helper but path-guard.sh wasn't on task-21 Target files list. The helper is the natural home for the canonical-form fix consumed by dispatch-companion.sh. Recommendation: amend task-21 Target files list retroactively in v0.7.3.

Neither finding implicates correctness or security regression — both are pure scope/spec-amendment requests.
