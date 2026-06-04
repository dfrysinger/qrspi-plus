---
finding_id: silent-failure-claude.finding-F02
severity: medium
change_type: correctness
artifact: code
round: 2
reviewer: silent-failure-claude
referenced_files:
  - agents/qrspi-finding-verifier.md#L82-L101
  - tests/acceptance/v07-phase1/test-phase1-acceptance.bats#L1089-L1095
---

## Sidecar step-6 template omits `reason:` field; HALLUCINATED greppability silently breaks if agent writes reason in prose body

### The template gap

`agents/qrspi-finding-verifier.md` step 6 shows the success-path sidecar template
as (lines 84–91):

```markdown
---
verifier_status: passed
score: <int 0..100>
---
<verifier reasoning prose — consumed by humans and future debug tooling, not by the fan-in script>
```

The template has **no `reason:` field** in the YAML frontmatter. The HALLUCINATED
reason-prefix requirement is stated only in a prose sentence at line 101:

> "When the score is `0` due to Cite Check failure (step 3.5), the `reason`
> value MUST start with the literal prefix `HALLUCINATED: ` so dropped sidecars
> can be greppable for the hallucination subset."

This leaves "reason value" ambiguous: does `reason` go in the YAML frontmatter
(as a peer of `verifier_status` and `score`) or in the prose body (the
`<verifier reasoning prose>` section)?

### Why this is a silent failure

The design relies on **greppability** for `HALLUCINATED: ` as the mechanism to
retrospectively identify which dropped findings were hallucinated (vs. ordinary
low-confidence drops). The test fixtures in TC4–TC7 write `reason:` as a
frontmatter key:

```bash
printf -- '---\nverifier_status: passed\nscore: %s\nreason: %s\n---\nCite check fixture sidecar.\n' \
  "$score" "$reason" >"$sidecar"    # ← reason: in frontmatter
```

But because TC4–TC7 **pre-construct** the sidecar (they never invoke the actual
verifier), **no test validates that the verifier agent itself writes `reason:` to
frontmatter**. A verifier agent that reads the step 6 template and writes:

```markdown
---
verifier_status: passed
score: 0
---
HALLUCINATED: file nonexistent/fabricated/path.md does not exist
```

(reason in prose body, not frontmatter) would:

1. **Still drop correctly** — fan-in reads `score: 0`, applies threshold → dropped.
   No fan-in error. All TC4–TC7 assertions still pass (they never invoke the verifier).
2. **Silently break greppability** — `grep "^reason: HALLUCINATED:" <sidecar>` returns
   nothing. Post-round diagnostics and any tooling that relies on `^reason:` to
   identify HALLUCINATED findings would silently miss the finding.
3. **TC1–TC3 still pass** — they only grep the agent file text, not actual sidecar output.

The failure mode is entirely silent: tests pass, the finding is dropped, but the
`HALLUCINATED:` signal is unrecoverable from the sidecar.

### Fix

Update the step 6 success-path template to show the HALLUCINATED-path variant
explicitly:

```markdown
On success (standard score):
---
verifier_status: passed
score: <int 0..100>
---
<verifier reasoning prose>

On Cite Check halt (score 0 / HALLUCINATED):
---
verifier_status: passed
score: 0
reason: HALLUCINATED: <diagnostic — file path / line range / quoted content / anchor>
---
<verifier reasoning prose explaining which citation failed>
```

This removes the ambiguity about whether `reason:` belongs in frontmatter or
body, and gives a verifier agent an unambiguous pattern to follow.

An integration test that actually runs the verifier on a fixture finding and
checks the sidecar output would provide runtime confirmation, but the template
fix alone materially reduces the ambiguity surface for the LLM agent.
