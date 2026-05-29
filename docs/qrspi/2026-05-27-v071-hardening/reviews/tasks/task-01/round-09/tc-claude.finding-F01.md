---
finding: F01
reviewer: tc-claude
round: 9
task: task-01
severity: moderate
change_type: correctness
file: tests/unit/test-run-third-party-llm.bats
lines: 589-597
---

# tc.F02 — Confirmed closed

`[ "$status" -ne 0 ]` → `[ "$status" -eq 1 ]` at line 726 (diff line 193) is
present and correct.  The assertion now pins the specific exit code rather than
accepting any non-zero status.

---

# tc.F01 — Parametric blocks present; one routing gap remains

Both parametric blocks (`VALUE` test: lines 529–600, `NAME` test: lines
616–689) iterate all 32 C0 bytes (octal 000–037 → 0x00–0x1F) with dual
assertions (`[ "$status" -eq 1 ]` + `[[ "$output" == *"header-validation"* ]]`)
and per-iteration failure diagnostics.  The byte-range enumeration is correct
and complete, hex conversion is sound, and the NUL/LF special cases are handled
appropriately.

## Remaining gap: CR (0x0D) in VALUE routed via integration path, not function-extraction

### What the NAME loop does (correct)

The `NAME` parametric loop (line 652) special-cases both LF and CR together:

```
012|015)
  # LF/CR: cannot survive awk record splitting cleanly; exercise
  # _control_char_check directly via function-extraction path.
```

The comment explicitly records the rationale: CR in a header name disrupts awk
record splitting on some platforms.

### What the VALUE loop does (gap)

The `VALUE` parametric loop (line 565) special-cases only LF:

```
012)
  # LF: cannot survive awk line-based config parse into HEADER_VALUES; ...
```

CR (octal `015`) falls through to the `*` default arm (lines 589–597), which
calls `_write_ctrl_config` + `_run_ctrl_check`.

### Why this matters

`_write_ctrl_config` generates the config line via:

```bash
printf '      %s: %s\n' "$hname" "$hval"
```

For the CR-in-VALUE iteration, `$hval` is `safe<CR>value`.  The file line
becomes:

```
      X-Param-Test: safe<CR>value<LF>
```

On CRLF-aware awk implementations (e.g., some BSD/macOS awk variants, or awk
invoked in environments with `RS` set to handle CR+LF), the parser may treat the
embedded CR as a line-ending component.  Under that interpretation, awk reads the
record as `      X-Param-Test: safe` (truncated at the CR), extracts value
`safe` (no control bytes), and passes it to `_control_char_check` without the
CR.  `_control_char_check` finds nothing to flag, the script proceeds to the
stub curl, the stub returns 0, and `[ "$status" -eq 1 ]` fails.

The same concern was already identified and mitigated for the NAME loop.  The
VALUE loop was left unpatched.

### Consequence

On affected platforms, the CR iteration of the VALUE parametric test will
produce a spurious test failure (exit 0 instead of 1), which looks like a test
harness failure rather than a detection gap.  More critically, on those same
platforms the actual CR-in-VALUE detection contract is not verified at all —
the parametric test silently stops pinning it.

### Fix

Add `015` to the VALUE loop's special-case arm alongside `012`, and generate an
isolated function-extraction test script in the same way the NAME loop does for
CR:

```diff
-      012)
+      012|015)
         # LF: cannot survive awk line-based config parse into HEADER_VALUES;
-        # exercise _control_char_check directly via function-extraction path.
+        # CR: disrupts awk record splitting on some platforms (same concern
+        # documented for the NAME loop); exercise _control_char_check directly
+        # via function-extraction path.
         local _fn_file_val="$FIXTURE_DIR/ctrl_fn_val_${_byte_hex}.sh"
```

The generated test script for CR should pass a literal CR inside the value
argument (single-quote string spanning the CR byte), mirroring the LF script
already generated.
