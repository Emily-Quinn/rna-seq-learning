# Project Plan

## Phase 1 — Toy pipeline (M2 MacBook, 16GB RAM)

Goal: run every stage of the pipeline end-to-end on small data, understand
what each tool does and why, and produce a real (if modest) differential
expression result.

| Step | Task | Est. time | Notes |
|---|---|---|---|
| 1 | Install conda/mamba, create env, verify tools run (`--version`) | 2–4 hrs | Use `CONDA_SUBDIR=osx-64` — see environment.yml notes |
| 2 | Download pasilla fastq files (GSE18508) | 30 min | Small, subsampled files available via Galaxy/ENA |
| 3 | FastQC + MultiQC on raw reads | 1 hr | `scripts/01_fastqc.sh` |
| 4 | Trim with fastp, re-run FastQC | 1 hr | `scripts/02_trim.sh` |
| 5 | Download Drosophila genome (BDGP6) + GTF annotation | 30 min | Small (~140Mb) |
| 6 | Build STAR index | 30–60 min | `scripts/03_star_index.sh` — should actually finish, unlike GRCh38 |
| 7 | Align reads with STAR | 30–60 min | `scripts/04_star_align.sh` |
| 8 | Post-alignment QC (qualimap, samtools flagstat) | 1–2 hrs | `scripts/05_post_align_qc.sh` |
| 9 | Generate bigWig tracks, GC bias check | 1–2 hrs | `scripts/06_bigwig.sh` — optional but good practice |
| 10 | Build transcriptome fasta, run Salmon quant | 1 hr | `scripts/07_salmon_quant.sh` |
| 11 | Import counts with tximport, run DESeq2 | 2–3 hrs | `dge/dge_analysis.R` |
| 12 | QC plots: PCA, MA plot, p-value histograms, volcano | 1–2 hrs | Same script |
| 13 | Functional analysis: GO enrichment (GoSeq) | 2–3 hrs | Optional stretch goal |
| 14 | Write up docs/phase1-notes.md, finalize README | 2–3 hrs | Include screenshots of key plots |

**Total: ~3–5 focused days**, realistically spread over 1–2 weeks around
other commitments.

## Phase 2 — Full-scale pipeline (Northeastern HPCC / Explorer)

Goal: repeat the identical pipeline against a real human dataset and full
GRCh38 genome, using proper cluster resource allocation (SLURM batch jobs,
not interactive laptop runs).

| Step | Task | Notes |
|---|---|---|
| 1 | Get Explorer account access sorted, load required modules or build a conda env on cluster | Check if STAR/Salmon/samtools already exist as modules — saves reinstall time |
| 2 | Write SLURM batch scripts for each stage (this is new vs. Phase 1) | Needs `#SBATCH` headers: partition, time, mem, cpus |
| 3 | Download/index GRCh38 (request enough mem: 32–64GB) | This step alone can take a few hours |
| 4 | Choose + download a real human dataset with a clear 2-group comparison | e.g. a public GEO dataset with disease vs. healthy or treated vs. untreated |
| 5 | Run full pipeline as batch jobs | Alignment per sample may take 30 min–a few hours depending on job resources |
| 6 | DESeq2 analysis (can run locally on laptop once counts are downloaded — much smaller than raw data) | |
| 7 | Compare Phase 1 vs Phase 2 experience in writeup: what changed at scale, what new problems (queueing, storage quotas, walltime limits) came up | |

Rough time budget: **1–3 weeks**, gated more by HPCC queue times and
learning SLURM than by pipeline complexity itself, since you'll have already
solved the "what does each command do" problem in Phase 1.

## Log

Use this section (or docs/phase1-notes.md / phase2-notes.md) to jot dated
notes as you go — useful both for debugging later and for turning into a
GitHub-friendly writeup.

- `YYYY-MM-DD`: ...
