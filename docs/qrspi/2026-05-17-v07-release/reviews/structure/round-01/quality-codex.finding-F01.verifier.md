score: 75
reason: Real correctness issue — structure.md line 18 prescribes passing `--transport-type codex-broker` as a CLI flag, but design.md lines 94–105 and the interface specification (lines 141–157) clearly establish that transport_type is a provider-config field resolved from config.md, not a dispatcher CLI argument. The inconsistency will break implementation if not resolved.
