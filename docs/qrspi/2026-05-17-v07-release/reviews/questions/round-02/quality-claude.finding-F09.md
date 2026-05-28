---
finding_id: R2-F09
severity: medium
change_type: correctness
referenced_files: [docs/qrspi/2026-05-17-v07-release/questions.md:L35]
artifact: questions
round: 2
reviewer: quality-claude
---

Q26's "lend themselves to mechanical replay" clause leaks the G5/G6 validation methodology.

The question reads: "What dispatcher classes exist today across `skills/` and `agents/`, what is the input/output shape of each, and which subset has bounded prompts that lend themselves to mechanical replay?" The third clause "bounded prompts that lend themselves to mechanical replay" lifts both the G5 framing ("Replay or A/B validation is referenced by the source issues as the way to determine which dispatcher/task combinations tolerate cheaper models") and the G6 framing ("A/B replay is the candidate validation methodology"). It also pre-asserts the candidate property — bounded prompts — that G5/G6 expect makes a dispatcher class amenable to replay validation.

A researcher reading only Q26 would correctly infer the project is shopping for a list of dispatchers suitable for an A/B replay experiment — exactly the cost-opt tolerance investigation G5/G6 frame.

Recommend trimming the third clause: "What dispatcher classes exist today across `skills/` and `agents/`, and what is the input/output shape of each?" The researcher reports the inventory; the "which are bounded enough for replay" filtering decision belongs to Design once the inventory is in hand.
