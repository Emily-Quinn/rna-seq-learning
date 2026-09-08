#!/usr/bin/env bash
# Step 5: Post-alignment QC — sort/index BAM, flagstat, qualimap.
# Usage: ./05_post_align_qc.sh <sample_name> <bam> <gtf> <out_dir>
set -euo pipefail

SAMPLE=${1:?Usage: 05_post_align_qc.sh <sample_name> <bam> <gtf> <out_dir>}
BAM=${2:?}
GTF=${3:?}
OUT_DIR=${4:?}

mkdir -p "$OUT_DIR"

SORTED_BAM="$OUT_DIR/${SAMPLE}.sorted.bam"

samtools sort "$BAM" -o "$SORTED_BAM"
samtools index "$SORTED_BAM"
samtools flagstat "$SORTED_BAM" > "$OUT_DIR/${SAMPLE}.flagstat"

qualimap bamqc -bam "$SORTED_BAM" -gff "$GTF" \
  -outdir "$OUT_DIR/${SAMPLE}-bamqc-qualimap-report" --java-mem-size=8G

qualimap rnaseq -bam "$SORTED_BAM" -gtf "$GTF" \
  -outdir "$OUT_DIR/${SAMPLE}-rnaseq-qualimap-report" --java-mem-size=8G

echo "QC complete for $SAMPLE. Percent reads mapped to exons:"
grep exonic "$OUT_DIR/${SAMPLE}-rnaseq-qualimap-report/rnaseq_qc_results.txt" \
  | cut -d '(' -f 2 | cut -d ')' -f1
