#!/usr/bin/env bash
# Step 6 (optional): Generate a normalized bigWig track for genome-browser
# visualization. GC-bias correction is skipped here for simplicity —
# see the CebolaLab README's computeGCBias/correctGCBias steps if you
# want to add that check.
#
# Usage: ./06_bigwig.sh <sample_name> <sorted_bam> <out_dir>
set -euo pipefail

SAMPLE=${1:?Usage: 06_bigwig.sh <sample_name> <sorted_bam> <out_dir>}
SORTED_BAM=${2:?}
OUT_DIR=${3:?}

mkdir -p "$OUT_DIR"

bamCoverage \
  -b "$SORTED_BAM" \
  -o "$OUT_DIR/${SAMPLE}.bw" \
  --normalizeUsing BPM \
  --samFlagExclude 512

echo "bigWig written to $OUT_DIR/${SAMPLE}.bw — load into IGV to view."
