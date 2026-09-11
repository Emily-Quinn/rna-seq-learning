#!/usr/bin/env bash
# Step 2: Adapter/quality trimming with fastp (paired-end).
# Usage: ./02_trim.sh <sample_name> <r1.fastq.gz> <r2.fastq.gz> <out_dir>
set -euo pipefail

SAMPLE=${1:?Usage: 02_trim.sh <sample_name> <r1.fastq.gz> <r2.fastq.gz> <out_dir>}
R1=${2:?}
R2=${3:?}
OUT_DIR=${4:?}

mkdir -p "$OUT_DIR"

fastp \
  -i "$R1" -I "$R2" \
  -o "$OUT_DIR/${SAMPLE}_R1.trimmed.fastq.gz" \
  -O "$OUT_DIR/${SAMPLE}_R2.trimmed.fastq.gz" \
  --detect_adapter_for_pe \
  -l 25 \
  -j "$OUT_DIR/${SAMPLE}.fastp.json" \
  -h "$OUT_DIR/${SAMPLE}.fastp.html"

echo "Trimmed reads written to $OUT_DIR"
echo "Re-run FastQC on the trimmed files to confirm improvement:"
echo "  fastqc $OUT_DIR/${SAMPLE}_R1.trimmed.fastq.gz -d $OUT_DIR -o $OUT_DIR"
