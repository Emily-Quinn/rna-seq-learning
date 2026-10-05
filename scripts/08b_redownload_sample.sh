#!/usr/bin/env bash
#SBATCH --job-name=redownload_SRR1039513
#SBATCH --partition=short
#SBATCH --time=01:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=4
#SBATCH --output=logs/redownload_%j.out
#SBATCH --error=logs/redownload_%j.err

set -euo pipefail

module load miniconda3/25.9.1
source activate rna-seq

OUT_DIR="/scratch/${USER}/airway_raw"

SAMPLES=(
  SRR1039520
  SRR1039521
)

for SRR in "${SAMPLES[@]}"; do
  echo "=== Re-downloading $SRR ==="
  prefetch "$SRR" -O "$OUT_DIR"
  fasterq-dump "$OUT_DIR/$SRR/$SRR.sra" -O "$OUT_DIR" --split-3 -e 4
  gzip "$OUT_DIR/${SRR}_1.fastq" "$OUT_DIR/${SRR}_2.fastq"
  echo "=== $SRR complete ==="
done
