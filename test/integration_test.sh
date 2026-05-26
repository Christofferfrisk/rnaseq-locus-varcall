#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
IMAGE="${IMAGE:-rnaseq-locus-varcall:local}"

python3 "$HERE/gen_test_data.py"

if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    docker build -t "$IMAGE" "$ROOT"
fi

DATA="$ROOT/test/data"
DOCKER_USER="$(id -u):$(id -g)"

docker run --rm --user "$DOCKER_USER" -v "$DATA":/data --entrypoint samtools "$IMAGE" sort -o /data/sampleA.bam /data/sampleA.sam
docker run --rm --user "$DOCKER_USER" -v "$DATA":/data --entrypoint samtools "$IMAGE" sort -o /data/sampleB.bam /data/sampleB.sam

printf "/data/sampleA.bam\n/data/sampleB.bam\n" > "$DATA/bams.txt"

docker run --rm --user "$DOCKER_USER" -v "$DATA":/data "$IMAGE" \
    --region testchr:400-600 \
    --ref /data/ref.fa \
    --bam-list /data/bams.txt \
    --out /data/out.vcf.gz

n=$(docker run --rm --user "$DOCKER_USER" -v "$DATA":/data --entrypoint bcftools "$IMAGE" view -H /data/out.vcf.gz | wc -l)
echo "integration test called $n variant site(s)"
[[ "$n" -ge 1 ]] || { echo "FAIL: expected >=1 variant, got $n" >&2; exit 1; }
echo "integration test PASSED"
