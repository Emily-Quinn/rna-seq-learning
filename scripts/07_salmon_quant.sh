#!/usr/bin/env bash
# Step 7: Build transcriptome fasta (once) and quantify with Salmon
# in alignment mode against the transcriptome BAM from STAR.
#
# Usage:
#   Build transcriptome (once per genome/annotation):
#     ./07_salmon_quant.sh build-transcriptome <genome_fasta> <gtf> <out_fasta>
#   Quantify a sample:
#     ./07_salmon_quant.sh quant <transcriptome_fasta> <toTranscriptome.bam> <out_dir>
set -euo pipefail

MODE=${1:?Usage: 07_salmon_quant.sh build-transcriptome or quant ...}

case "$MODE" in
  build-transcriptome)
    GENOME_FASTA=${2:?}
    GTF=${3:?}
    OUT_FASTA=${4:?}
    gffread -w "$OUT_FASTA" -g "$GENOME_FASTA" "$GTF"
    echo "Transcriptome fasta written to $OUT_FASTA"
    ;;
  quant)
    TRANSCRIPTOME_FASTA=${2:?}
    BAM=${3:?}
    OUT_DIR=${4:?}
    mkdir -p "$OUT_DIR"
    salmon quant \
      -t "$TRANSCRIPTOME_FASTA" \
      --libType A \
      -a "$BAM" \
      -o "$OUT_DIR" \
      --gcBias --seqBias
    echo "Quantification complete. Counts in $OUT_DIR/quant.sf"
    ;;
  *)
    echo "Unknown mode: $MODE (expected build-transcriptome or quant)" >&2
    exit 1
    ;;
esac
