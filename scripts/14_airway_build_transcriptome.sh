#!/usr/bin/env bash
#SBATCH --job-name=airway_transcriptome
#SBATCH --partition=short
#SBATCH --time=02:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=2
#SBATCH --output=logs/airway_transcriptome_%j.out
#SBATCH --error=logs/airway_transcriptome_%j.err

set -euo pipefail

module load miniconda3/25.9.1
source activate rna-seq

GENOME_FASTA="/scratch/${USER}/airway_genome/GRCh38.primary_assembly.genome.fa"
GTF="/scratch/${USER}/airway_genome/gencode.v46.primary_assembly.annotation.gtf"
OUT_FASTA="/scratch/${USER}/airway_genome/gencode_v46_transcriptome.fasta"

bash scripts/07_salmon_quant.sh build-transcriptome "$GENOME_FASTA" "$GTF" "$OUT_FASTA"
