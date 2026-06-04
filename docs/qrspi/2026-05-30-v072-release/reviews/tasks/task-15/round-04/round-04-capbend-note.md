---
round: 4
fix_cycle: 4
cap_bend: true
authority: "User input: cap bend as needed to get good quality final result; substantive refactors not OK (these are additive guards, not refactors)"
---
R4 verification pass: 7/8 reviewers CLEAN; both R3 fixes confirmed closed. sf-claude surfaced 2
sibling instances (L496, L618) of the same extract_section masking pattern in T15-authored G18 pins,
outside the narrowed R4 diff. Fix is the identical additive `|| return 1` guard. Bending the 3-cycle cap
once for fix-4 (strictly additive, no refactor) for consistency — leaving them ships T15 with the exact
flaw fixed at L564.
