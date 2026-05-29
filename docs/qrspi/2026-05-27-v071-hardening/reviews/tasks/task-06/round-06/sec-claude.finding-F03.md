---
finding_id: R6-F03
severity: informational
change_type: scope
referenced_files: [scripts/run-codex-review.sh]
artifact: task-06/scripts/run-codex-review.sh
round: 6
reviewer: sec-claude
persistence_note: orchestrator-persisted (reviewer chat-only fallback)
failing_safe: true
---

**Title:** Whitelist Gaps for System-Controlled Prefixes on Linux (failing-safe)

**Location:** `detect_host` whitelist — `/usr/*`, `/opt/*`, `/Applications/*`.

**Environments that fail the marker check (returns `claude-code` instead of `copilot-cli`):**
- Ubuntu Snap: `/snap/bin/gh`
- NixOS: `/nix/store/<hash>-gh-<ver>/bin/gh`
- Linux Homebrew: `/home/linuxbrew/.linuxbrew/bin/gh`
- Nix user profile: `~/.nix-profile/bin/gh`

**Security verdict:** Failing-safe. Returning `claude-code` when `copilot-cli` would be correct is the secure choice. No attacker can exploit a false-negative here.

**Impact:** On Snap/NixOS CI or dev machines, `detect_host` always returns `claude-code` even with a legitimate Copilot CLI session. Operational gap, not security vulnerability. May need a separate follow-up to track legitimate-install path-prefix coverage.
