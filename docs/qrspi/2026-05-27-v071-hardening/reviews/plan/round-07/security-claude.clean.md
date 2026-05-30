---
status: clean
reviewer: security-claude
round: 7
artifact: plan.md
---

# Security review — clean

## R6→R7 diff scope

The only change between R6 and R7 in plan.md is a wording refinement to two Task 7 mock-evidence bullets (lines 224–225):

- Before: "captured stdout provides evidence that the dispatch invoked the mock transport rather than falling back to a different code path"
- After: "captured stdout contains a distinguishable marker string emitted by the mock transport (a value the mock produces and no other code path produces), proving the dispatch invoked the mock rather than falling back"

This is a **security-positive** refinement. It tightens the fail-open detection contract for acceptance tests by requiring a uniquely-identifying marker rather than unspecified "evidence." A future implementer cannot satisfy the bullet with a generic non-empty-stdout assertion that could be produced by a silent fallback code path. This directly hardens the test surface against the class of fail-open regressions where the dispatcher silently routes to the wrong transport and still exits 0.

The companion structure.md change (cache_control row mirror) is documentation-only and security-neutral.

## R5-F01 fix confirmation (mismatch + transport-fail fail-open)

The R5 finding identified that a mismatch-warning path combined with a transport-failure exit code could leave callers unable to distinguish dispatch failure from success. The R5 fix added explicit propagation bullets that remain load-bearing in R7:

- **plan.md line 202** (Task 6 unit surface): "When the dispatch-surface detects a mismatch (warning emitted) and then invokes a mocked transport that exits with a non-zero exit code, the dispatch surface propagates that same non-zero exit code to the caller. The mismatch warning path does not suppress dispatch failures."
- **plan.md line 227** (Task 7 acceptance surface): identical assertion at the SKILL/end-to-end layer.

Read together with the non-mismatch transport-failure propagation bullets at lines 201/226 ("no suppression, no log-and-continue"), the mismatch+transport-fail combined fail-open is closed at both the unit and acceptance layers. **Confirmed: these bullets remain load-bearing in R7.**

## Set-aside acceptance

Set-asides S1–S5 acknowledged. S1 (DKR6 mismatch is warning-only, dispatch not blocked, per design.md DKR6 line 55) is safely scoped because the warning does not gate dispatch but transport non-zero exit still propagates via the bullets above — callers still distinguish failure from success, which is the actual fail-closed concern. Not re-raising.

## Categories reviewed

- **Fail-closed**: Transport non-zero propagation covered at both unit (line 201) and acceptance (line 226) layers; mismatch+transport-fail covered at lines 202/227; `check_codex_available` non-zero propagation covered at line 221. Mock-evidence tightening at lines 224–225 further reduces silent-fallback fail-open risk. No new gaps.
- **Input validation**: `detect_host` 2-branch probe with explicit coverage of unset, empty string, non-`1` values, and unrelated env vars (lines 186–192); `check_codex_available` unrecognized-host rejection at line 196. No new gaps.
- **Auth/Authz**: S3 set-aside acknowledged; nothing introduced by R7 diff that touches new auth-gated surfaces.
- **Insecure defaults**: No default-value or fallback behavior introduced or modified by the R7 diff. The 2-branch `detect_host` default to `claude-code` for non-`1` values is a documented design decision (DKR6) and is not a credential/permission default.

No findings.
