#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<EOF
Usage: call_variants --region CHR:START-END --ref REF.fa --bam-list BAMS.txt --out OUT.vcf.gz [options]

RNA-seq-aware variant calling at a user-defined locus.

Required:
  --region    samtools-style region string (e.g. 7:1000000-1000500)
  --ref       reference FASTA (.fai built if missing)
  --bam-list  newline-delimited file of BAM paths (.bai built if missing)
  --out       output bgzipped VCF path

Optional:
  --threads     threads for bcftools (default 4)
  --max-depth   per-sample read cap passed to mpileup (default 10000)
  --min-mq      minimum mapping quality (default 20)
  --min-bq      minimum base quality (default 20)
  --keep-indels include indels (default: skipped, since RNA-seq indels are mostly splicing artefacts)
EOF
}

THREADS=4
MAX_DEPTH=10000
MIN_MQ=20
MIN_BQ=20
SKIP_INDELS=1

while [[ $# -gt 0 ]]; do
    case "$1" in
        --region)       REGION="$2"; shift 2 ;;
        --ref)          REF="$2"; shift 2 ;;
        --bam-list)     BAM_LIST="$2"; shift 2 ;;
        --out)          OUT="$2"; shift 2 ;;
        --threads)      THREADS="$2"; shift 2 ;;
        --max-depth)    MAX_DEPTH="$2"; shift 2 ;;
        --min-mq)       MIN_MQ="$2"; shift 2 ;;
        --min-bq)       MIN_BQ="$2"; shift 2 ;;
        --keep-indels)  SKIP_INDELS=0; shift ;;
        -h|--help)      usage; exit 0 ;;
        *)              echo "Unknown argument: $1" >&2; usage; exit 2 ;;
    esac
done

: "${REGION:?--region is required}"
: "${REF:?--ref is required}"
: "${BAM_LIST:?--bam-list is required}"
: "${OUT:?--out is required}"

[[ -f "$REF" ]]      || { echo "Reference not found: $REF" >&2; exit 1; }
[[ -f "$BAM_LIST" ]] || { echo "BAM list not found: $BAM_LIST" >&2; exit 1; }
[[ -f "${REF}.fai" ]] || samtools faidx "$REF"

while read -r bam; do
    [[ -z "$bam" ]] && continue
    [[ -f "$bam" ]] || { echo "Missing BAM: $bam" >&2; exit 1; }
    [[ -f "${bam}.bai" || -f "${bam%.bam}.bai" ]] || samtools index "$bam"
done < "$BAM_LIST"

mkdir -p "$(dirname "$OUT")"

indel_flag=()
[[ "$SKIP_INDELS" -eq 1 ]] && indel_flag+=(--skip-indels)

bcftools mpileup \
    --threads "$THREADS" \
    --fasta-ref "$REF" \
    --regions "$REGION" \
    --bam-list "$BAM_LIST" \
    --annotate FORMAT/AD,FORMAT/DP \
    --max-depth "$MAX_DEPTH" \
    --min-MQ "$MIN_MQ" \
    --min-BQ "$MIN_BQ" \
    "${indel_flag[@]}" \
    --ff UNMAP,SECONDARY,QCFAIL,DUP \
    --output-type u \
| bcftools call \
    --threads "$THREADS" \
    --multiallelic-caller \
    --variants-only \
    --output-type z \
    --output "$OUT"

bcftools index "$OUT"

n_sites=$(bcftools view -H "$OUT" | wc -l)
echo "Wrote $OUT ($n_sites variant sites)"
