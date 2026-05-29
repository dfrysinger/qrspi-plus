---
finding_id: R4-F01
severity: medium
change_type: security
referenced_files:
  - skills/using-qrspi/SKILL.md
  - agents/*.md (T9 sweep)
  - tests/unit/test-using-qrspi-vocab.bats
artifact: integration
round: 4
reviewer: security-claude
---

## `trusted_path:` short-circuit reopens G7b/#204 silent-fallback class one layer deeper after T9 + T10 combine

**Surface:** `skills/using-qrspi/SKILL.md:470` (T10 R2 fail-loud paragraph), `:474` (`trusted_path:` description), `:506` (precedence chain step 4), `:508` (`trusted_path:` short-circuit prose).

### The cross-task interaction

This finding emerges *only* from combining T9 and T10; neither task in isolation creates it.

**T9 effect (already merged in earlier rounds):** Removed the `model:` field from all 41 `agents/*.md` frontmatters. After T9, every agent's "agent-bundled default" (step 4 in the precedence chain at SKILL.md:506) resolves to **nothing** — there is no model name bundled with any agent anymore.

**T10 R2 add (this round):** Added the fail-loud paragraph at SKILL.md:470:

> "The dispatcher … halts and reports the missing or invalid entry. **The dispatcher never falls back silently to the agent-bundled default** and **never passes the dispatch through to the host CLI's silent re-routing** — both fallbacks would reproduce the G7b/#204 silent-fallback class this hardening release exists to close."

This paragraph is scoped, by its surrounding sentences, to the three `model_routing:` lookup-failure cases (unknown host, unmapped tier, bare short-form value). It is *not* a global rule covering every dispatch resolution path.

**The gap:** The `trusted_path:` short-circuit at SKILL.md:508 (unchanged in T10) reads:

> "`trusted_path:` is a separate short-circuit outside this chain: when an agent-file path or role name matches a `trusted_path:` entry, **the dispatcher skips steps 1–3 and routes directly to the agent-bundled default (step 4)**."

After T9, step 4 is empty for every agent. A `trusted_path:` match therefore resolves to an undefined value, with no fail-loud rule documented for this case. The R2 paragraph's prohibition ("never falls back silently to the agent-bundled default") is *literally contradicted* by the still-present trusted_path: prose ("routes directly to the agent-bundled default"). The contradiction does not auto-resolve in favor of fail-loud — the prose order is:
1. R2 fail-loud paragraph at L470 (model_routing:-scoped)
2. trusted_path: short-circuit at L474 / L508 (explicitly bypasses model_routing:)

A dispatcher implementer reading these two sections together has no documented contract for what to do when `trusted_path:` matches and step 4 is empty. The three behaviorally distinct possibilities are:

| Implementation choice | G7b/#204 status |
|---|---|
| (a) Halt loudly, report empty agent-bundled default | Closed |
| (b) Silently fall back to `model_routing:` (tier from `model_role:` or `inherit`) | **Reopened** — silent fallback to model_routing |
| (c) Silently fall through to host CLI's default model | **Reopened** — the exact silent host-CLI re-routing R2 forbids |

The SKILL.md does not pin (a). The R2 paragraph forbids (c) only in the `model_routing:`-failure path, not in the trusted_path: path. Two of three plausible implementations reproduce the silent-fallback class this release exists to close.

### Why this is cross-task, not per-task

- **T9 in isolation** is fine: removing `model:` makes "tier" the canonical vocabulary, and the `model_routing:` table covers every normal dispatch.
- **T10 in isolation** would be fine if step 4 were still meaningful: trusted_path:'s entire purpose is "I trust this agent's choice of model — use what's in its frontmatter".
- **The combination** strips meaning from step 4 (T9) while leaving trusted_path: pointing at it (T10), and adds a fail-loud paragraph (T10 R2) whose scope explicitly excludes the trusted_path: branch.

The T9 review and T10 per-task review each cleared their own scope; this gap is only visible by tracing trusted_path: across the T9/T10 boundary.

### Why the vocab pins do not catch this

`tests/unit/test-using-qrspi-vocab.bats` (new in T10) pins:
- absence of retired role→provider/model wording
- presence of `claude-code:` / `copilot-cli:` / versioned tier rows
- fail-loud wording (`halts and reports`, `never falls back silently`) **within the `#### \`model_routing:\` block` H4 body**
- absence of anti-pattern wording **within the same H4 body**

The pins extract the `model_routing:` H4 with `_extract_h4`. They do not pin the `#### \`trusted_path:\` block` body or the `#### Precedence chain` body. A future edit that strengthens trusted_path: to fail-loud would not RED-fail any pin; a future edit that weakens or silently elides the gap would also not RED-fail any pin. The vocab pins are by design about the model_routing: schema replacement (T10 R1 fix), not about the cross-task trusted_path: ↔ step-4 contradiction.

### Why severity is medium (not low)

- The G7b/#204 silent-fallback class is the load-bearing class this hardening release exists to close (goals.md G7b). Reopening it through a different code path defeats the release's stated security goal.
- Configuration is repo-maintainer-controlled (not user-controlled), which caps the exploitability dimension. But:
  - A maintainer who sets `trusted_path:` is explicitly granting "use the agent's chosen model, bypass operator overrides" — and after T9 that grant silently translates to either (b) "use whatever model_routing: says" or (c) "use whatever the host CLI picks". The grant's semantic intent becomes undefined, and the difference between (a/b/c) is invisible from the config layer.
  - In Copilot CLI specifically, path (c) means falling through to the host's default model with no warning surface (the `model_role:` → tier `→` versioned ID chain has been bypassed, and Copilot CLI's "model not available" warning is what the versioned IDs in the `copilot-cli:` column exist to avoid).

Per the review-criteria guidance, this is not strictly access control (`trusted_path:` is not user-controlled at runtime), so the "access control is High minimum" rule does not pin a higher floor. Severity: medium.

### Suggested fix (single-paragraph SKILL.md edit, no schema change)

Add one sentence to the `#### \`trusted_path:\` block` H4 (after the existing "matching agents or roles bypass the chain entirely" paragraph at SKILL.md:486), and broaden the R2 fail-loud paragraph's scope by one clause. Concretely:

1. **At SKILL.md:486 (end of trusted_path: H4):** Append:
   > "When `trusted_path:` matches but the matched agent's frontmatter declares no `model:` field (the state established for all agents after the T9 sweep), step 4 has no concrete value to return. The dispatcher halts and reports the trusted_path: match plus the empty agent-bundled default rather than silently falling through to `model_routing:` (which trusted_path: explicitly bypasses) or to the host CLI's silent re-routing. The G7b/#204 silent-fallback class is closed for both the `model_routing:` path and the trusted_path: path."

2. **Add a vocab pin** in `tests/unit/test-using-qrspi-vocab.bats` that extracts the `#### \`trusted_path:\` block` H4 body and asserts the same `halts and reports` + `never (falls|fall) back silently` substring pair. This mirrors the existing R2 fail-loud pin for the model_routing: H4 and prevents regression of the trusted_path: side of the contract.

Either step 1 alone or steps 1+2 together close the cross-task gap. Step 2 is recommended because the existing pins demonstrably permit the gap to recur silently otherwise.

### What does NOT need to change

- No schema change. `model_routing:`, `trusted_path:`, and the four-tier vocabulary are unaffected.
- No T9 revert. The `model:` field deletion remains correct under the host→tier→model abstraction.
- No new code. The dispatcher's runtime behavior is downstream; the contract repair happens at the SKILL.md prose layer + one new test pin.

### Verification trace

I traced the trusted_path: short-circuit explicitly across the T9 → T10 boundary:

- **T9 boundary:** confirmed via T10's own R2 paragraph wording ("the state established for all 41 agents after the T9 sweep" at SKILL.md:544) that step 4 is universally empty post-T9.
- **T10 boundary:** confirmed at SKILL.md:470 that the fail-loud paragraph names "agent-bundled default" and "host CLI's silent re-routing" as the two forbidden fallbacks — *for the `model_routing:` failure path only*, evidenced by the immediate prior sentence enumerating the three `model_routing:` failure cases.
- **trusted_path: branch:** confirmed at SKILL.md:508 that the short-circuit routes "directly to the agent-bundled default (step 4)" — i.e., to the very thing R2 forbids elsewhere. The contradiction is on-page in the merged SKILL.md.
- **Test coverage:** confirmed the new vocab pins extract only the model_routing: H4 (`_extract_h4 "$USING" '\`model_routing:\` block'`); the trusted_path: H4 has no corresponding pin.
