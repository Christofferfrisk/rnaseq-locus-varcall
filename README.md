# rnaseq-locus-varcall

[![CI](https://github.com/Christofferfrisk/rnaseq-locus-varcall/actions/workflows/docker.yml/badge.svg)](https://github.com/Christofferfrisk/rnaseq-locus-varcall/actions/workflows/docker.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Containerised, RNA-seq-aware variant calling at a user-defined locus. Wraps `bcftools mpileup | bcftools call` with sensible defaults for RNA-seq BAMs (high per-sample read caps, duplicates and secondary alignments excluded, indels skipped by default).

The tool is locus-scoped on purpose: it is built for follow-up genotyping at a small region of interest across a cohort, not for whole-genome calling. Typical use is checking whether known regulatory or coding variants are present in an existing RNA-seq dataset without re-running a full GATK pipeline.

## Quickstart

```bash
docker run --rm -v "$PWD":/work \
    ghcr.io/christofferfrisk/rnaseq-locus-varcall:latest \
    --region 7:1000000-1000500 \
    --ref     /work/ref.fa \
    --bam-list /work/bams.txt \
    --out     /work/out.vcf.gz
```

`bams.txt` is a newline-delimited list of BAM paths inside the container. The reference FASTA and BAMs are auto-indexed if `.fai`/`.bai` are missing.

## Options

| Flag | Default | Description |
|------|---------|-------------|
| `--region` | required | samtools-style region (e.g. `7:1000000-1000500`) |
| `--ref` | required | reference FASTA |
| `--bam-list` | required | newline-delimited BAM paths |
| `--out` | required | output bgzipped VCF |
| `--threads` | 4 | bcftools threads |
| `--max-depth` | 10000 | per-sample read cap for `mpileup` (default 250 silently discards reads at high-coverage RNA-seq sites) |
| `--min-mq` | 20 | minimum mapping quality |
| `--min-bq` | 20 | minimum base quality |
| `--keep-indels` | off | include indels (default: skipped, since RNA-seq indels are mostly splicing artefacts) |

## Caveats for RNA-seq variant calling

- A>G and T>C variants in transcribed regions may be ADAR RNA-editing events rather than germline SNPs. Cross-check candidate sites against [REDIportal](http://srv00.recas.ba.infn.it/atlas/) before interpreting any A>G call as a regulatory variant.
- Allele-specific expression skews allele balance: do not infer zygosity from VAF without orthogonal genotyping data.
- Coverage tracks transcript abundance, not genomic copy number, so absence of evidence is not evidence of absence.

## Build from source

```bash
git clone https://github.com/Christofferfrisk/rnaseq-locus-varcall.git
cd rnaseq-locus-varcall
docker build -t rnaseq-locus-varcall .
```

## Smoke test

```bash
bash test/smoke_test.sh
```

Generates a deterministic 1 kb synthetic reference and two synthetic BAMs (one reference-allele-only, one with an introduced SNP), runs the pipeline inside the container, and asserts that at least one variant is called.

## Tools

- [samtools 1.20](https://www.htslib.org/)
- [bcftools 1.20](https://samtools.github.io/bcftools/)
- [micromamba](https://mamba.readthedocs.io/) (base image)

## License

MIT. See [LICENSE](LICENSE).

## Citation

If this tool is useful in published work, please cite via [CITATION.cff](CITATION.cff).
