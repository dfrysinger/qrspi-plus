---
finding_id: R1-F01
severity: medium
change_type: scope
referenced_files: [docs/qrspi/2026-05-30-v072-release/structure.md:L356-L365]
artifact: structure
round: 1
reviewer: scope-claude
---

## Boundary drift — Interface §12 embeds actual prose body of `skills/_shared/verifier-filter-rule.md`

**What the artifact does.**  
Interface §12 ("Shared verifier filter rule snippet") at lines 356–365 pre-authors the complete wording of `skills/_shared/verifier-filter-rule.md`:

```markdown
## Verifier Filter Rule

Apply the verifier score only to `style`, `clarity`, and `correctness` findings.
- `style` and `clarity` require the higher threshold.
- `correctness` uses the lower hardening threshold.
- `scope` and `intent` bypass score filtering.
```

**Why this is out of scope.**  
The OWNS/DEFERS contract (v0.7.1, unchanged by G35 D2) defers "Actual prompt or SKILL.md text content → Plan / Implement." The file `skills/_shared/verifier-filter-rule.md` is a prose snippet that will be `!cat`-included directly into orchestrator skill prose (per Slice 1.1's Responsibility column: "Hold the single threshold/filter rule consumed by orchestrator prose and verifier fan-in"). Its wording — the actual rule sentences — is Plan/Implement deliverable content, not a structural interface declaration.

The contrast within the artifact makes the problem legible: Interfaces §5 and §6 (the altitude-boundary snippets) correctly use `<boundary rule prose>` and `- ...` placeholders to declare the file's section structure without pre-authoring the body. Interface §12 does the opposite — it pastes the complete rule text rather than declaring a section heading and role.

**What Structure should do instead.**  
Structure owns the section heading and the file's role at the interface boundary:

```markdown
### 12. Shared verifier filter rule snippet

Concrete v0.7.2 path: `skills/_shared/verifier-filter-rule.md`.
Required section: `## Verifier Filter Rule`.
Role: single threshold/filter rule; consumed by `scripts/verifier-fan-in.sh`, apply-fix, and reviewer-facing documentation.
```

The actual rule sentences belong in the Plan/Implement authoring pass for `skills/_shared/verifier-filter-rule.md`.
