#!/usr/bin/env bash
#SBATCH --job-name=airway_fastqc
#SBATCH --partition=short
#SBATCH --time=02:00:00
#SBATCH --mem=8G
#SBATCH --cpus-per-task=4
#SBATCH --output=logs/airway_fastqc_%j.out
#SBATCH --error=logs/airway_fastqc_%j.err

set -euo pipefail

module load miniconda3/25.9.1
source activate rna-seq

FASTQ_DIR="/scratch/${USER}/airway_raw"
OUT_DIR="/scratch/${USER}/airway_qc/raw_fastqc"

bash scripts/01_fastqc.sh "$FASTQ_DIR" "$OUT_DIR"
