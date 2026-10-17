#!/usr/bin/env bash
#SBATCH --job-name=airway_qc
#SBATCH --partition=short
#SBATCH --time=06:00:00
#SBATCH --mem=24G
#SBATCH --cpus-per-task=4
#SBATCH --array=0-7
#SBATCH --output=logs/airway_postqc_%A_%a.out
#SBATCH --error=logs/airway_postqc_%A_%a.err

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

BAM="/scratch/${USER}/airway_aligned/${SAMPLE}.Aligned.out.bam"
GTF="/scratch/${USER}/airway_genome/gencode.v46.primary_assembly.annotation.gtf"
OUT_DIR="/scratch/${USER}/airway_qc/post_align"

mkdir -p "$OUT_DIR"

echo "=== Post-alignment QC: $SAMPLE ==="

bash scripts/05_post_align_qc.sh "$SAMPLE" "$BAM" "$GTF" "$OUT_DIR"

echo "=== $SAMPLE QC complete ==="
