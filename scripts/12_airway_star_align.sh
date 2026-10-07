#!/usr/bin/env bash
#SBATCH --job-name=airway_align
#SBATCH --partition=short
#SBATCH --time=06:00:00
#SBATCH --mem=48G
#SBATCH --cpus-per-task=8
#SBATCH --array=0-7
#SBATCH --output=logs/airway_align_%A_%a.out
#SBATCH --error=logs/airway_align_%A_%a.err

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

GENOME_DIR="/scratch/${USER}/airway_genome/star_index"
TRIMMED_DIR="/scratch/${USER}/airway_trimmed"
OUT_DIR="/scratch/${USER}/airway_aligned"

mkdir -p "$OUT_DIR"

echo "=== Aligning $SAMPLE ==="

STAR \
  --runThreadN 8 \
  --genomeDir "$GENOME_DIR" \
  --readFilesIn "$TRIMMED_DIR/${SAMPLE}_R1.trimmed.fastq.gz" "$TRIMMED_DIR/${SAMPLE}_R2.trimmed.fastq.gz" \
  --outFileNamePrefix "$OUT_DIR/${SAMPLE}." \
  --readFilesCommand "gzip -dc" \
  --outSAMtype BAM Unsorted \
  --quantTranscriptomeBan Singleend \
  --outFilterType BySJout \
  --alignSJoverhangMin 8 \
  --outFilterMultimapNmax 20 \
  --alignSJDBoverhangMin 1 \
  --outFilterMismatchNmax 999 \
  --outFilterMismatchNoverReadLmax 0.04 \
  --alignIntronMin 20 \
  --alignIntronMax 1000000 \
  --alignMatesGapMax 1000000 \
  --quantMode TranscriptomeSAM \
  --outSAMattributes NH HI AS NM MD

echo "=== $SAMPLE alignment complete ==="
