---
finding_id: R5-F01
severity: high
change_type: correctness
referenced_files: [scripts/_resolve-lib.sh]
---
none-tier halt silently fails when the tier row carries an inline YAML comment.
`resolve_model` detects `none` with `grep -Eq "^[[:space:]]*${tier}:[[:space:]]+none[[:space:]]*$"`; the `[[:space:]]*$` anchor is defeated by the trailing `# operator opts in` on the canonical `extra-low:  none   # operator opts in` row (config.md:39, mirrored in using-qrspi template). The none-check fails, the row is non-empty, so it falls through to the sed echo path and returns EXIT 0 with garbage stdout `none      # operator opts in`. EMPIRICALLY CONFIRMED: `CONFIG_MD=<canonical> resolve_model extra-low` returns exit 0 (should halt). `extra-low` is THE documented operator opt-in tier shipped as `none`, so the resolver's core safety property (halt-on-none) is broken for the exact tier it ships as none — directly reinstating the G7b/#204 silent-fallback class this hardening release exists to close. Convergent: sf-claude F01 (CRITICAL), cq-claude F01 (high). Fix: normalize the row value once (strip whitespace-preceded `#` comment + surrounding whitespace) and use that normalized value for BOTH the none-check and the emitted stdout.
