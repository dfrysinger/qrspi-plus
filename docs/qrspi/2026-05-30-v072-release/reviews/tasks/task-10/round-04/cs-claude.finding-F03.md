---
finding_id: R4-F03
severity: low
change_type: style
referenced_files: [tests/acceptance/v07-phase1/test-phase1-acceptance.bats]
---

# printf %s\\n where echo equivalent

In AC5, `printf '%s\n' "$yaml"` is used eight times (five positive-assertion pipes, three diagnostic prints in error branches). Since `$yaml` is multi-line `awk` output that already ends in a newline, `printf '%s\n'` and `echo` produce identical byte sequences. `echo "$yaml"` is simpler and the conventional idiom for printing a pre-captured multi-line variable.
