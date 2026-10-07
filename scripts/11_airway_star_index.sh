#!/usr/bin/env bash
#SBATCH --job-name=airway_star_index
#SBATCH --partition=short
#SBATCH --time=08:00:00
#SBATCH --mem=64G
#SBATCH --cpus-per-task=8
#SBATCH --output=logs/airway_star_index_%j.out
#SBATCH --error=logs/airway_star_index_%j.err

set -euo pipefail

module load miniconda3/25.9.1
source activate rna-seq

GENOME_FASTA="/scratch/${USER}/airway_genome/GRCh38.primary_assembly.genome.fa"
GTF="/scratch/${USER}/airway_genome/gencode.v46.primary_assembly.annotation.gtf"
OUT_DIR="/scratch/${USER}/airway_genome/star_index"
READ_LENGTH=62

mkdir -p "$OUT_DIR"

STAR \
  --runThreadN 8 \
  --runMode genomeGenerate \
  --genomeDir "$OUT_DIR" \
  --genomeFastaFiles "$GENOME_FASTA" \
  --sjdbGTFfile "$GTF" \
  --sjdbOverhang $((READ_LENGTH - 1))

echo "Index built in $OUT_DIR"
