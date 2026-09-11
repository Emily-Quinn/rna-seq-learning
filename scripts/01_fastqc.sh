#!/usr/bin/env bash
# Step 1: Pre-alignment QC on raw fastq files.
# Usage: ./01_fastqc.sh <fastq_dir> <out_dir>
set -euo pipefail

FASTQ_DIR=${1:?Usage: 01_fastqc.sh <fastq_dir> <out_dir>}
OUT_DIR=${2:?Usage: 01_fastqc.sh <fastq_dir> <out_dir>}

mkdir -p "$OUT_DIR"

for f in "$FASTQ_DIR"/*.fastq.gz; do
  echo "Running FastQC on $f"
  fastqc "$f" -o "$OUT_DIR"
done

echo "Combining reports with MultiQC..."
multiqc "$OUT_DIR" -o "$OUT_DIR"

echo "Done. See $OUT_DIR/multiqc_report.html"
