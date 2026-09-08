#!/usr/bin/env bash
# Step 3: Build a STAR genome index.
#
# Phase 1 (laptop): use the Drosophila BDGP6 genome + annotation — small
#   enough to index in minutes with modest --genomeSAindexNbases.
# Phase 2 (HPCC): use GRCh38 no-alt + gencode annotation, request 32-64GB
#   mem in your SLURM script, and do NOT override --genomeSAindexNbases.
#
# Usage: ./03_star_index.sh <genome_fasta> <gtf> <out_dir> <read_length> [sa_index_nbases]
set -euo pipefail

GENOME_FASTA=${1:?Usage: 03_star_index.sh <genome_fasta> <gtf> <out_dir> <read_length> [sa_index_nbases]}
GTF=${2:?}
OUT_DIR=${3:?}
READ_LENGTH=${4:?}
SA_INDEX_NBASES=${5:-14}   # STAR default is 14; for small genomes (e.g. Drosophila
                           # ~140Mb) STAR recommends min(14, log2(GenomeLength)/2 - 1)
                           # ~= 11 for Drosophila. Override for small-genome runs.

SJDB_OVERHANG=$((READ_LENGTH - 1))

mkdir -p "$OUT_DIR"

STAR \
  --runThreadN 4 \
  --runMode genomeGenerate \
  --genomeDir "$OUT_DIR" \
  --genomeFastaFiles "$GENOME_FASTA" \
  --sjdbGTFfile "$GTF" \
  --sjdbOverhang "$SJDB_OVERHANG" \
  --genomeSAindexNbases "$SA_INDEX_NBASES"

echo "Index built in $OUT_DIR"
