---
finding_id: R2-F01
severity: high
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/plan.md:L841-L856]
artifact: plan
round: 2
reviewer: silent-failure-claude
---

T27 specifies that when a sibling finding body in `wave_context:` assembly contains a sentinel-collision token, the orchestrator either strips the offending token "with a logged diagnostic" or excludes the finding "with a loud diagnostic." Both branches are described as producing some kind of diagnostic, but neither branch requires that the reviewer dispatched against the task receives a signal that its companion body is incomplete or that findings were redacted.

The word "logged" in "strips the offending token (with a logged diagnostic naming the source finding)" is the problem. A logged diagnostic written to an orchestrator log or stderr is invisible to the `qrspi-visual-fidelity-reviewer` agent that receives the assembled `wave_context:` companion. From the reviewer's perspective, the companion body is either complete or absent — it has no way to detect that relevant sibling findings were silently removed. The reviewer may conclude "no relevant sibling visual context found" and emit a clean statement to that effect, when in reality sibling findings existed but were stripped from the companion without the reviewer's knowledge. This degrades cross-task visual consistency review quality silently.

The T30 wave-context-shape test pin (L917-L928) verifies only that "no nested sentinel reaches the outer wrapper body" — it asserts absence of the malformed payload but does not require that the reviewer receive a signal about the redaction.

Resolution: T27's description and T30's wave-context-shape test expectation must require that the `wave_context:` companion body include an explicit machine-readable REDACTION-NOTICE entry when one or more sibling findings are stripped or excluded due to sentinel collision, naming the source task ID and the count of redacted findings. The visual-fidelity reviewer's output contract (T28) must then require that the reviewer acknowledge the REDACTION-NOTICE rather than treating the companion as complete. This closes the log-and-continue silent path: the reviewer knows its context is incomplete and can surface the limitation in its findings rather than issuing false-confidence conclusions.
