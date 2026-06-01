---
finding_id: R4-F04
reviewer_tag: stitching-audit
severity: low
change_type: correctness
gap_class: seam-mismatch
referenced_files:
  - docs/qrspi/2026-05-30-v072-release/structure.md
  - docs/qrspi/2026-05-30-v072-release/design.md
line_range: [205, 215]
---

# Interface §3 PATH B side-effect description does not name the `--tag` argument passed to `dispatch-companion.sh`, leaving a seam with §14's `--tag`-required launch form

## Gap description

R3 added `--tag <reviewer-tag>` to Interface §14 (`dispatch-companion.sh` launch form) and
updated Interface §10's `split_cmd` example to include `--tag`. But Interface §3
(`dispatch-agent.sh`) describes the PATH B side effect only as:

> "background entries after dispatch-companion.sh returns JOB_ID on third-party path"
> (structure.md lines 205–215, Side effect comment)

§3 does not name `--tag` as one of the arguments dispatch-agent.sh passes when it invokes
dispatch-companion.sh. Yet §14 requires `--tag <reviewer-tag>` in the launch form:

> "Usage (launch): dispatch-companion.sh --vendor <vendor> --model <model-id>
> --prompt-file <abs-path> --round-dir <abs-round-dir> --tag <reviewer-tag>"
> (structure.md line 415)

And §14's `await` side-effect writes `<round-dir>/.dispatch/<tag>.raw` — which means the
`--tag` value passed at launch time is the key that allows `await-round.sh` to subsequently
invoke `split_cmd` pointing at the right `.raw` file. The chain requires:

  dispatch-agent.sh --tag X → dispatch-companion.sh --tag X → <tag>.raw → split_cmd --tag X

§3 describes the entry into this chain without naming `--tag`, while §14 requires it and
§10/§16 depend on it. This is a seam mismatch: the caller (§3) and the callee (§14)
disagree on the documented interface at the argument level.

## Authority (cite design.md section)

design.md CD-1, dispatch-agent.sh PATH B (line 78):
> "PATH B (third-party): invoke `dispatch-companion.sh` to launch background; capture jobId;
> append entry to `.dispatch-manifest.json` with `mode: background`, `status: pending`,
> `await_cmd`, `split_cmd`."

design.md CD-1, component #5 (lines 100–102):
> "`scripts/dispatch-companion.sh` (rename of `run-third-party-llm.sh`) — vendor-routing
> tier underneath dispatch-agent. Takes `--vendor` + resolved `--model`; routes to
> vendor-specific transport."

The design.md description of dispatch-companion already uses `--vendor` / `--model` as named
args. `--tag` was added in R3; design.md's concise component description did not enumerate
all args, but the R3 fix added `--tag` to structure's §14 without updating §3's side-effect
description to reflect the call.

## Impact on implementation

An implementer of `dispatch-agent.sh` working only from §3 will see PATH B described as
"invoke dispatch-companion.sh to launch background; capture jobId." They won't know to pass
`--tag` to dispatch-companion.sh. When they later implement dispatch-companion.sh from §14
(which shows `--tag` as part of the launch form and uses it to name the `.raw` file), the
two implementations will be inconsistent unless the implementer cross-reads both interfaces
and infers the argument.

The `.raw` file naming (`<tag>.raw`) creates a hard dependency: the tag passed at launch
**must** be the same tag used to name the `.raw` file, which is the same tag in `split_cmd`.
If `--tag` is not passed at launch, dispatch-companion.sh has no tag to use and the file
naming breaks.

## Fix (Structure-altitude only)

Extend §3's PATH B side-effect comment to name `--tag` as a required argument to
dispatch-companion.sh:

> Side effect (PATH B): invokes `dispatch-companion.sh --vendor <vendor> --model <model>
> --prompt-file <abs-path> --round-dir <abs-round-dir> **--tag <reviewer-tag>**`; captures
> JOB_ID from stdout; appends manifest entry to `<round-dir>/.dispatch-manifest.json` with
> `mode: background`, `status: pending`, `await_cmd: "dispatch-companion.sh await <JOB_ID>"`,
> `split_cmd: "third-party-finding-splitter.sh --round-dir <abs-round-dir> --tag <reviewer-tag>"`.

This closes the seam: every argument named in §14's launch form is now traceable to the §3
caller description that passes it.
