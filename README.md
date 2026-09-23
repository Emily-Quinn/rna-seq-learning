# RNA-seq Pipeline: Learning Project

A hands-on implementation of a standard RNA-seq differential expression pipeline,
built in two phases: a small-scale run on a laptop, then a full-scale run on
Northeastern's HPCC (Discovery cluster) against the real human genome.

Pipeline steps and reference commands are adapted from the
[CebolaLab/RNA-seq](https://github.com/CebolaLab/RNA-seq) tutorial, which covers:
pre-alignment QC → STAR alignment → post-alignment QC → Salmon quantification →
DESeq2 differential expression → functional enrichment (GO / GSEA).

## Why two phases?

Full-genome alignment (STAR indexing GRCh38) needs 30GB+ RAM and hours of
compute per sample — not realistic on a 16GB M2 laptop. So:

- **Phase 1 (laptop)** proves out every tool and command on a small genome
  (Drosophila) where indexing/alignment finishes in minutes, not hours.
- **Phase 2 (HPCC)** re-runs the *same* pipeline against a real human dataset,
  at full scale, using Discovery's compute/memory allocation.

## Dataset

**Phase 1:** [GSE18508](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE18508)
(the "pasilla" dataset) — Drosophila melanogaster, *pasilla* gene knockdown
(treated) vs. control (untreated), paired-end reads. This is the same dataset
used in the official Bioconductor DESeq2 vignette, so there's a strong
reference to check work against.

**Phase 2:** TBD — a public human RNA-seq dataset from GEO/SRA with a clear
two-group comparison (chosen once Phase 1 is complete).

## Repo structure

```
rna-seq-learning/
├── README.md                  <- you are here
├── PLAN.md                    <- step-by-step checklist + status log
├── environment.yml            <- conda env (M2/ARM notes included)
├── scripts/                   <- shell scripts, one per pipeline stage
│   ├── 01_fastqc.sh
│   ├── 02_trim.sh
│   ├── 03_star_index.sh
│   ├── 04_star_align.sh
│   ├── 05_post_align_qc.sh
│   ├── 06_bigwig.sh
│   └── 07_salmon_quant.sh
├── dge/
│   └── dge_analysis.R         <- DESeq2 + QC plots + functional analysis
└── docs/
    ├── phase1-notes.md        <- lab-notebook style log for the toy run
    └── phase2-notes.md        <- lab-notebook style log for the HPCC run
```

## Status

- [x] Phase 1: environment setup
- [x] Phase 1: QC + trimming
- [x] Phase 1: alignment (STAR)
- [x] Phase 1: post-alignment QC
- [ ] Phase 1: quantification (Salmon)
- [ ] Phase 1: DESeq2 differential expression
- [ ] Phase 1: functional analysis
- [ ] Phase 1: writeup
- [ ] Phase 2: HPCC environment / module setup
- [ ] Phase 2: full human genome index
- [ ] Phase 2: full pipeline re-run
- [ ] Phase 2: writeup + comparison to Phase 1

See [PLAN.md](PLAN.md) for the detailed checklist and time log.

## Credits

Pipeline steps adapted from [CebolaLab/RNA-seq](https://github.com/CebolaLab/RNA-seq)
(Hannah Maude, Imperial College London). This repo documents an independent
learning exercise working through that pipeline on new data.
