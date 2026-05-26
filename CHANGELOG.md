# Changelog

## v0.1.0 — 2026-05-26

Initial release.

- Containerised samtools 1.20 + bcftools 1.20 environment via micromamba.
- `call_variants` CLI with RNA-seq-aware defaults (excludes duplicates, secondary, QC-fail; skips indels by default).
- Auto-indexes the reference FASTA and input BAMs when indexes are missing.
- Synthetic smoke test fixture under `test/`.
- GitHub Actions workflow building the image and running the smoke test on every push.
