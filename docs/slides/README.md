# QRSPI Slide Deck (Mirror)

`qrspi-deck.pdf` is a 156-page PDF extracted from the Coding Agents Summit / South Bay Summit 2026 conference deck, covering only Dex Horthy's QRSPI talk "From RPI to QRSPI — Lessons Learned Rolling out Research/Plan/Implement to thousands of engineers".

**Source:** [docs.google.com/presentation/d/1mnp0CzrRS02Y0t0vGvqX-_M5IbYPjFoZ](https://docs.google.com/presentation/d/1mnp0CzrRS02Y0t0vGvqX-_M5IbYPjFoZ/mobilepresent?slide=id.g3bef903f3c9_0_435)

**Speaker:** Dex Horthy (HumanLayer).

## Range

The full conference deck is 491 pages (multiple speakers). Dex's talk occupies pages **291-446** of the full deck. The later pages 447-491 contain the unrelated LangChain + Arcade deck "How to Make a Coding Agent a General Purpose Agent" by Harrison Chase and Sam Partee.

## How this file was produced

```bash
curl -L -o full-deck.pdf "https://docs.google.com/presentation/d/1mnp0CzrRS02Y0t0vGvqX-_M5IbYPjFoZ/export?format=pdf"
qpdf --empty --pages full-deck.pdf 291-446 -- qrspi-deck.pdf
```

`qpdf` available via `brew install qpdf`. (Earlier attempts with `pdfseparate` + `pdfunite` produced a bloated PDF with xref errors; qpdf's `--empty --pages` is the clean path.)

## Notes

- To read inline: any PDF viewer.
- To extract per-slide PNGs: `pdftoppm -png qrspi-deck.pdf slide` produces `slide-001.png` through `slide-156.png`.
- File size ~10 MB — commit-friendly without Git LFS.

## Related

- `../qrspi-deep-dive.md` — curated notes from this talk's content
- `../qrspi-reference.md` — condensed 9-step plugin-extended reference
- `../upstream/` — other external QRSPI/ACE source material
