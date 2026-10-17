#!/usr/bin/env bash
#SBATCH --job-name=airway_download
#SBATCH --partition=short
#SBATCH --time=04:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=4
#SBATCH --output=logs/airway_download_%j.out
#SBATCH --error=logs/airway_download_%j.err

set -euo pipefail

module load miniconda3/25.9.1
source activate rna-seq

OUT_DIR="/scratch/${USER}/airway_raw"
mkdir -p "$OUT_DIR"
cd "$OUT_DIR"

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

for SRR in "${SAMPLES[@]}"; do
  echo "=== Downloading $SRR ==="
  prefetch "$SRR" -O "$OUT_DIR"
  fasterq-dump "$OUT_DIR/$SRR/$SRR.sra" -O "$OUT_DIR" --split-3 -e 4
  gzip "$OUT_DIR/${SRR}_1.fastq" "$OUT_DIR/${SRR}_2.fastq"
  echo "=== $SRR complete ==="
done

echo "All downloads complete."
