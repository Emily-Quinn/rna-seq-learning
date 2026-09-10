# Phase 1 Notes — Toy Pipeline (Drosophila / pasilla dataset)

Use this as a running lab notebook. Dated entries, screenshots of key plots,
and anything that broke + how it got fixed. This becomes the bulk of the
GitHub writeup for this phase.

## Setup

- Date started: 2026-09-10
- Conda env creation notes (any osx-arm64/Rosetta issues hit): Hit a Terms of Service prompt for the default Anaconda channels — fixed with `conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main` (and same for `pkgs/r`). Otherwise both `rna-seq` and `deseq2` environments built cleanly using `CONDA_SUBDIR=osx-64` to get Intel/Rosetta builds of STAR and Salmon.

## Dataset

- Samples used: GSM461177, GSM461178 (untreated); GSM461180, GSM461181 (treated) — pasilla dataset, GEO GSE18508
- Source / download method: Downloaded via SRA using `prefetch` + `fasterq-dump`. Resolved each GSM → SRX → SRR accession manually via the GEO web pages, since some GSM/SRX experiments split into 2 SRR runs (lanes) that needed concatenating into one fastq pair per sample afterward.

## Pipeline run log

### 1. Pre-alignment QC

-

### 2. Trimming

-

### 3. STAR indexing + alignment

-

### 4. Post-alignment QC

-

### 5. Salmon quantification

-

### 6. DESeq2 differential expression

- Coefficient tested:
- Number of significant genes (padj<0.05):
- Number of significant genes (padj<0.05, |log2FC|>2):
- Key plots: (embed pca_plot.png, volcano_plot.png, ma_plot.png here)

## What surprised me / what I'd do differently

-

## Comparison prep for Phase 2

- Runtime for each stage (for later comparison against HPCC):
