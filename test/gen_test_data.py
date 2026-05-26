#!/usr/bin/env python3
"""Deterministically generate a synthetic reference and two SAM files for the integration test.

Sample A: reference allele only at the variant site.
Sample B: alternate allele at the variant site (high depth, high BQ/MQ).
"""
from __future__ import annotations

import os
import random
import sys
from pathlib import Path

OUT_DIR = Path(__file__).parent / "data"
CHROM = "testchr"
REF_LEN = 1000
VARIANT_POS = 500
ALT_BASE = "G"
READ_LEN = 75
N_READS_PER_SAMPLE = 60
SEED = 42


def make_reference() -> str:
    rng = random.Random(SEED)
    seq = "".join(rng.choice("ACGT") for _ in range(REF_LEN))
    if seq[VARIANT_POS - 1] == ALT_BASE:
        seq = seq[: VARIANT_POS - 1] + "A" + seq[VARIANT_POS:]
    return seq


def write_fasta(path: Path, seq: str) -> None:
    with path.open("w", newline="\n") as fh:
        fh.write(f">{CHROM}\n")
        for i in range(0, len(seq), 60):
            fh.write(seq[i : i + 60] + "\n")


def make_sam(path: Path, sample: str, ref: str, introduce_alt: bool) -> None:
    rng = random.Random(SEED + (1 if introduce_alt else 0))
    qual = "I" * READ_LEN
    lines = [
        "@HD\tVN:1.6\tSO:coordinate",
        f"@SQ\tSN:{CHROM}\tLN:{REF_LEN}",
        f"@RG\tID:{sample}\tSM:{sample}\tPL:ILLUMINA\tLB:lib1",
    ]
    span = (VARIANT_POS - READ_LEN + 5, VARIANT_POS - 5)
    starts = sorted(rng.randint(span[0], span[1]) for _ in range(N_READS_PER_SAMPLE))
    for i, start in enumerate(starts, 1):
        seq = list(ref[start - 1 : start - 1 + READ_LEN])
        if introduce_alt:
            offset = VARIANT_POS - start
            if 0 <= offset < READ_LEN:
                seq[offset] = ALT_BASE
        lines.append(
            "\t".join(
                [
                    f"{sample}_r{i}",
                    "0",
                    CHROM,
                    str(start),
                    "60",
                    f"{READ_LEN}M",
                    "*",
                    "0",
                    "0",
                    "".join(seq),
                    qual,
                    f"RG:Z:{sample}",
                ]
            )
        )
    path.write_text("\n".join(lines) + "\n", newline="\n")


def main() -> int:
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    ref = make_reference()
    write_fasta(OUT_DIR / "ref.fa", ref)
    make_sam(OUT_DIR / "sampleA.sam", "sampleA", ref, introduce_alt=False)
    make_sam(OUT_DIR / "sampleB.sam", "sampleB", ref, introduce_alt=True)
    print(f"Wrote fixtures to {OUT_DIR}")
    print(f"  reference base at pos {VARIANT_POS}: {ref[VARIANT_POS - 1]}")
    print(f"  introduced ALT in sampleB: {ALT_BASE}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
