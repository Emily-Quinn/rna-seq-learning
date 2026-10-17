#!/usr/bin/env bash
#SBATCH --job-name=airway_trim
#SBATCH --partition=short
#SBATCH --time=04:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=4
#SBATCH --output=logs/airway_trim_%j.out
#SBATCH --error=logs/airway_trim_%j.err

set -euo pipefail

module load miniconda3/25.9.1
source activate rna-seq

RAW_DIR="/scratch/${USER}/airway_raw"
OUT_DIR="/scratch/${USER}/airway_trimmed"
mkdir -p "$OUT_DIR"

SAMPLES=(
  SRR1039508
  SRR1039509
  SRR1039512
  SRR1039513
  SRR1039516
  SRR1039517
  SRR1039520
  SRR1039521
)

for SAMPLE in "${SAMPLES[@]}"; do
  echo "=== Trimming $SAMPLE ==="
  bash scripts/02_trim.sh "$SAMPLE" \
    "$RAW_DIR/${SAMPLE}_1.fastq.gz" \
    "$RAW_DIR/${SAMPLE}_2.fastq.gz" \
    "$OUT_DIR"
  echo "=== $SAMPLE complete ==="
done

echo "All trimming complete."
