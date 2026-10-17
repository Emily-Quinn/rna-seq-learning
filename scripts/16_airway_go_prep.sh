#!/usr/bin/env bash
#SBATCH --job-name=airway_go_prep
#SBATCH --partition=short
#SBATCH --time=01:00:00
#SBATCH --mem=16G
#SBATCH --cpus-per-task=2
#SBATCH --output=logs/airway_go_prep_%j.out
#SBATCH --error=logs/airway_go_prep_%j.err

set -euo pipefail

module load miniconda3/25.9.1
source activate deseq2

Rscript export_sig_genes_airway.R
