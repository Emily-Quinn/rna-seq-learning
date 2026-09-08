#!/usr/bin/env bash
# Step 4: Align trimmed reads to the genome + transcriptome with STAR.
# Follows the ENCODE-recommended parameters used in the CebolaLab pipeline.
#
# Usage: ./04_star_align.sh <sample_name> <genome_dir> <r1.trimmed.fastq.gz> <r2.trimmed.fastq.gz> <out_dir>
set -euo pipefail

SAMPLE=${1:?Usage: 04_star_align.sh <sample_name> <genome_dir> <r1> <r2> <out_dir>}
GENOME_DIR=${2:?}
R1=${3:?}
R2=${4:?}
OUT_DIR=${5:?}

mkdir -p "$OUT_DIR"

STAR \
  --runThreadN 4 \
  --genomeDir "$GENOME_DIR" \
  --readFilesIn "$R1" "$R2" \
  --outFileNamePrefix "$OUT_DIR/${SAMPLE}." \
  --readFilesCommand zcat \
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

echo "Alignment complete. Key outputs in $OUT_DIR:"
echo "  ${SAMPLE}.Aligned.out.bam                (genome alignment)"
echo "  ${SAMPLE}.Aligned.toTranscriptome.out.bam (for Salmon quantification)"
echo "  ${SAMPLE}.Log.final.out                   (alignment summary stats)"
