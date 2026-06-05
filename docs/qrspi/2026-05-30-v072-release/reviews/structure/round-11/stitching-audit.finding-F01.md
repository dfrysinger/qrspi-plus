# stitching-audit.finding-F01

**reviewer_tag:** stitching-audit
**round:** 11
**artifact:** structure
**section:** ## Per-File Specifications
**severity:** must-fix
**kind:** citation drift

## Finding

Check 10 fails: multiple verbatim-block `**Source:**` line ranges no longer point at the cited design.md payload. Spot checks found stale ranges, e.g. structure.md L435 cites design.md L1830, but the `0 / HALLUCINATED` payload is at design.md L1823; structure.md L660 cites design.md L1546-L1557, but the `Sweep Task Contract` payload starts at design.md L1541 and ends at L1550; structure.md L724 cites design.md L1561-L1566, but the `Sweep-task detection` payload is at design.md L1554-L1559; structure.md L2649 cites design.md L3003, while the cited introducer prose appears in the G35 consumer-edit bullet at design.md L2996. A broader scan found this class in 34 of 49 verbatim blocks.

## Required fix

Update every affected `**Source:** design.md ... (Lx-Ly)` range in structure.md so it covers the actual design.md payload/marker after the R11 restructure. Re-run the citation check after edits and ensure each cited range resolves to the lifted payload, modulo the documented display-fence, Placement/Consumers metadata, and Old/New carve-outs.
