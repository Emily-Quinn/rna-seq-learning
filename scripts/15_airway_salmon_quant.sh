#!/usr/bin/env bash
#SBATCH --job-name=airway_salmon
#SBATCH --partition=short
#SBATCH --time=02:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=4
#SBATCH --array=0-7
#SBATCH --output=logs/airway_salmon_%A_%a.out
#SBATCH --error=logs/airway_salmon_%A_%a.err

set -euo pipefail

module load miniconda3/25.9.1
source activate rna-seq

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

SAMPLE="${SAMPLES[$SLURM_ARRAY_TASK_ID]}"

TRANSCRIPTOME_FASTA="/scratch/${USER}/airway_genome/gencode_v46_transcriptome.fasta"
BAM="/scratch/${USER}/airway_aligned/${SAMPLE}.Aligned.toTranscriptome.out.bam"
OUT_DIR="/scratch/${USER}/airway_quant/${SAMPLE}"

echo "=== Quantifying $SAMPLE ==="

bash scripts/07_salmon_quant.sh quant "$TRANSCRIPTOME_FASTA" "$BAM" "$OUT_DIR"

echo "=== $SAMPLE quantification complete ==="
