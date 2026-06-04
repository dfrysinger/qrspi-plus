---
finding_id: R1-F01
reviewer_tag: security-codex
round: 1
task: 6
severity: medium
change_type: correctness
referenced_files:
  - agents/qrspi-finding-verifier.md
---

# F01 — Unvalidated `referenced_files` enables arbitrary file read (data exfiltration)

## Location

`agents/qrspi-finding-verifier.md:45` (Step 3): "For each `referenced_files` entry, Read it." No boundary/allowlist constraints required by the contract.

## Attack scenario

An attacker who can influence a finding file (directly, or via prompt-injecting upstream reviewer output that becomes a finding's `referenced_files` value) sets:

```yaml
referenced_files:
  - /etc/passwd
  - /Users/runner/.ssh/id_rsa
  - /home/runner/.aws/credentials
```

The verifier is instructed to read each path, pulling sensitive host files into model context and potentially into sidecar reasoning output. The verifier's reasoning text becomes the markdown body of `.score.md`, which then flows into batch-gate reports and is potentially committed.

## Threat model

The finding file is reviewer-written. A compromised or prompt-injected reviewer subagent could write a finding with attacker-chosen `referenced_files`. This expands the exfiltration surface beyond the reviewer's own context to whatever the verifier process can read.

## Scope note

T06's Definition of Done is scoped to the `.score.yml → .score.md` extension lock plus `score:` integer 0–100 constraint. Adding `referenced_files` path validation is OUT of T06's declared scope — but the finding is reported here per reviewer-protocol because the verifier agent file is the surface where this constraint would land.

## Suggested remediation

Add a path-validation requirement to the verifier agent contract:

> For each `referenced_files` entry, validate before Read:
> (a) path must be relative to the artifact root (no absolute paths, no `..` traversal);
> (b) path must canonicalize within the artifact directory tree OR within a declared `upstream_paths:` allowlist;
> (c) any path failing validation is logged in the sidecar body as `referenced_files_rejected:` with the offending path AND the rejection reason; the verifier does NOT Read it.

This is a v0.7.3 candidate — same pattern as Wave 1 T12's `parse_and_validate` defense (input validation at trust boundary).
