---
finding_id: R1-F03
severity: medium
change_type: correctness
referenced_files:
  - docs/qrspi/2026-05-17-v07-release/plan.md:L195-L207
  - docs/qrspi/2026-05-17-v07-release/plan.md:L968-L982
artifact: plan
round: 1
reviewer: security-claude
---

Task 03 specifies that the universal dispatcher reads `<artifact-dir>/config.md` to resolve the `providers:` entry named by `--provider`. The `--artifact-dir` flag is required; an invocation missing it exits 1. However, the task description and test expectations do not specify what happens when `--artifact-dir` is present but points to a path outside the intended artifact directory — i.e., a path traversal scenario.

The `--artifact-dir` value is an absolute path supplied at call time from the orchestrator side. If a future call site (or a compromised sub-subagent dispatched in the G3 post-approval split context) is able to influence the `--artifact-dir` value, a traversal to an attacker-controlled directory containing a forged `config.md` would let the attacker route the dispatch to a provider of their choice with an API key environment variable of their choice.

The test expectations for T03 cover: "Invocation missing any required flag (`--artifact-dir`, `--provider`, `--model`, `--output-file`) exits 1 and names the missing flag." They also cover: "When `--provider` does not match any entry in `<artifact-dir>/config.md`, the script exits 1 with a named provider-resolution diagnostic." But neither T03 nor T07 specifies a test case requiring that `--artifact-dir` must resolve to a path that is a directory (not a file), and neither specifies validation that the path is within expected bounds or is a real git-tracked artifact directory.

A more immediate concern is T33 (`scripts/g4-cache-probe.sh`), which takes `--report-out <path>` and writes the spike report to whatever path is supplied. The test expectations for T33 cover "Invoking `scripts/g4-cache-probe.sh` without `--report-out` exits non-zero with a validation diagnostic on stderr" and "A dispatcher failure during any of the three dispatches causes the script to exit 1." But there is no test expectation that the `--report-out` path is validated to be within the artifact directory (e.g., `docs/qrspi/...`) rather than an arbitrary filesystem location. If an adversarial input can influence the `--report-out` argument, the script can be directed to overwrite an arbitrary file the process has write access to.

The risk is moderate in this codebase because the dispatcher is orchestrated by trusted QRSPI skills rather than directly by external users. However, the plan's explicit security model for G2 includes guard_marker_injection as an injection defense, implying sensitivity to path-based attacks is relevant.

Resolution: T03's test expectations should add: "When `--artifact-dir` does not refer to an existing directory, the script exits 1 with a named path-validation diagnostic before reading `config.md`." T33's test expectations should add: "When `--report-out` names a path outside the declared spike-deliverable location under `docs/qrspi/`, the script exits 1 with a named path-validation diagnostic." These additions keep the scripts fail-closed on bad path arguments rather than attempting to read from or write to unexpected filesystem locations.
