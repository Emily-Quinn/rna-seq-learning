# RNA-seq Pipeline: Learning Project

A hands-on implementation of a standard RNA-seq differential expression pipeline,
built in two phases: a small-scale run on a laptop, then a full-scale run on
Northeastern's HPCC (Explorer cluster) against the real human genome.

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
  at full scale, using Explorer's compute/memory allocation.

## Dataset

**Phase 1:** [GSE18508](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE18508)
(the "pasilla" dataset) — Drosophila melanogaster, *pasilla* gene knockdown
(treated) vs. control (untreated), paired-end reads. This is the same dataset
used in the official Bioconductor DESeq2 vignette, so there's a strong
reference to check work against.

**Phase 2:** [GSE52778](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE52778)
(the "airway" dataset) — four primary human airway smooth muscle cell
lines, each with a dexamethasone-treated and untreated sample (8 samples
total, paired design). SRA Study: SRP033351, BioProject: PRJNA229998.
This is the standard human dataset used in DESeq2/tximport teaching
materials (the Bioconductor `airway` package), giving a reference result
to validate against — same rationale as Phase 1's pasilla choice.
Source: Himes et al. 2014, PLoS One, PMID 24926665.

| Run (SRR) | GSM | Cell line | Condition |
|---|---|---|---|
| SRR1039508 | GSM1275862 | N61311 | untreated |
| SRR1039509 | GSM1275863 | N61311 | treated (dex) |
| SRR1039512 | GSM1275866 | N052611 | untreated |
| SRR1039513 | GSM1275867 | N052611 | treated (dex) |
| SRR1039516 | GSM1275870 | N080611 | untreated |
| SRR1039517 | GSM1275871 | N080611 | treated (dex) |
| SRR1039520 | GSM1275874 | N061011 | untreated |
| SRR1039521 | GSM1275875 | N061011 | treated (dex) |

## Repo structure

```
rna-seq-learning/
├── README.md                  <- you are here
├── PLAN.md                    <- step-by-step checklist + status log
├── environment.yml            <- conda env (M2/ARM notes included)
├── samples.txt                <- Phase 1 sample sheet (sample, quant.sf path, condition)
├── tx2gene.txt                <- Phase 1 transcript-to-gene mapping (FlyBase r6.69)
├── phase2_sample_accessions.txt  <- Phase 2 sample sheet (SRR, GSM, cell line, condition)
├── scripts/                   <- shell scripts, one per pipeline stage
│   ├── 01_fastqc.sh
│   ├── 02_trim.sh
│   ├── 03_star_index.sh
│   ├── 04_star_align.sh
│   ├── 05_post_align_qc.sh
│   ├── 06_bigwig.sh
│   ├── 07_salmon_quant.sh
│   ├── 08_download_airway.sh     <- Phase 2: SRA download (prefetch + fasterq-dump)
│   ├── 08b_redownload_sample.sh  <- Phase 2: single/batch re-download helper
│   ├── 09_airway_fastqc.sh       <- Phase 2: FastQC + MultiQC via SLURM
│   └── 10_airway_trim.sh         <- Phase 2: fastp trimming via SLURM
├── dge/
│   ├── dge_analysis.R         <- DESeq2 + QC plots + functional analysis
│   └── results/                <- Phase 1 DESeq2 output (plots, top-gene CSVs)
└── docs/
    ├── phase1-notes.md        <- lab-notebook style log for the toy run
    ├── phase2-notes.md        <- lab-notebook style log for the HPCC run
    └── images/                <- figures referenced in the notes (e.g. IGV screenshots)
```

## Status

- [x] Phase 1: environment setup
- [x] Phase 1: QC + trimming
- [x] Phase 1: alignment (STAR)
- [x] Phase 1: post-alignment QC
- [x] Phase 1: quantification (Salmon)
- [x] Phase 1: DESeq2 differential expression
- [ ] Phase 1: functional analysis
- [ ] Phase 1: writeup
- [x] Phase 2: HPCC environment / module setup
- [ ] Phase 2: full human genome index
- [ ] Phase 2: full pipeline re-run
- [ ] Phase 2: writeup + comparison to Phase 1

See [PLAN.md](PLAN.md) for the detailed checklist and time log.

## Credits

Pipeline steps adapted from [CebolaLab/RNA-seq](https://github.com/CebolaLab/RNA-seq)
(Hannah Maude, Imperial College London). This repo documents an independent
learning exercise working through that pipeline on new data.
