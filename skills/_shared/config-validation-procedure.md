# Config validation procedure — `model_routing:`

Shared validation procedure consumed by the dispatch chain (`scripts/_resolve-lib.sh`, `scripts/dispatch-agent.sh`) and `!cat`-included by skill prose that reads routing config. It fails loudly with repair-or-abort guidance whenever the `model_routing:` configuration in `config.md` is missing or malformed.

## When this procedure runs

At config-load time and on every dispatch, before any agent is routed.

## Validation checks (fail loud, repair-or-abort)

1. **Missing `model_routing:` block.** When `config.md` does not contain a `model_routing:` block at all, validation fails: the routing layer has no tier→`(vendor, model)` mapping to resolve against. This is a hard validation failure, not a silent fallback.

   - **Repair:** add the five-tier `model_routing:` block (with `default_tier: medium`) to `config.md` per the schema in `config.md` § "Model routing" and `skills/using-qrspi/SKILL.md` § "`model_routing:` block".
   - **Abort:** if the operator cannot supply the block, abort the run — do not dispatch against an absent or backfilled-in-memory routing table.

2. **Malformed tier values.** When a tier row is present but its value is malformed — not `none` and not a well-formed `{ vendor:, model: }` object, an invalid/unknown tier key outside `{extra-low, low, medium, high, extra-high}`, or a bad `default_tier:` value — validation fails and names the offending tier.

   - **Repair:** correct the malformed tier row to a `{ vendor: <vendor>, model: <model> }` object or the literal `none`; correct `default_tier:` to one of the five tier names.
   - **Abort:** if the value cannot be repaired, abort rather than guessing a substitute model.

3. **`none`-tier dispatch (cross-link).** A dispatch resolving to a tier configured as `none` halts loudly with a diagnostic naming the unconfigured tier — see `scripts/_resolve-lib.sh` (`resolve_model`). That halt is the runtime counterpart of this load-time validation; neither path silently falls back to a neighboring tier.

## Repair-or-abort contract

Every failure above surfaces a diagnostic that (a) names the specific problem (missing block, malformed tier, offending value), and (b) offers the operator a concrete repair path *or* an explicit abort. The procedure never silently mutates on-disk `config.md` and never substitutes an unannounced default — repair-or-abort is the only sanctioned outcome.
