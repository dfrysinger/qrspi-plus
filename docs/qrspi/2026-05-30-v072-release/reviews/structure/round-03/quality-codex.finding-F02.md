---
finding_id: R3-F02
severity: medium
change_type: correctness
referenced_files: [structure.md]
line_range: 434-441
---
Interface 16 ("Third-party finding splitter") is not fully concrete on the zero-findings output contract: it says "writes NO_FINDINGS sentinel file" but does not specify the exact sentinel filename/path shape. Given this release's strict per-finding/clean-sentinel disk contract, this interface should name the exact emitted clean file path pattern to avoid implementation drift.
