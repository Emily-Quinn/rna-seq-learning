#!/usr/bin/env bash
#SBATCH --job-name=airway_go_enrich
#SBATCH --partition=short
#SBATCH --time=01:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=2
#SBATCH --output=logs/airway_go_enrich_%j.out
#SBATCH --error=logs/airway_go_enrich_%j.err

set -euo pipefail

module load miniconda3/25.9.1
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate deseq2

Rscript scripts/17_airway_go_enrichment.R
