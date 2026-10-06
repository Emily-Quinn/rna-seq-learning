# Phase 2 Notes — Full-Scale Pipeline (Human genome, Northeastern HPCC)

## Setup

- Date started: October 1, 2026
- Explorer cluster account/access notes: already had access; logged in via
  `ssh user@login.explorer.northeastern.edu`
- Storage layout: git repo cloned to `~/rna-seq-learning` (home, 75GB
  fixed quota, not purged); actual pipeline data goes in
  `/scratch/user/` (large quota, purged monthly — do not leave
  important data here long-term); conda environments built in home
  (`~/.conda/envs/`) rather than scratch, so a monthly purge doesn't
  force re-installing them mid-project.

## Environment setup

Built two conda environments directly on Explorer, matching Phase 1's
local setup:

- `rna-seq` — from the repo's `environment.yml` (no `CONDA_SUBDIR=osx-64`
  needed here, unlike the Mac — Explorer is native Linux x86_64, so all
  bioinformatics tools installed with native builds). STAR correctly
  resolved to the pinned 2.7.10b version (confirmed via `STAR --version`),
  avoiding the Phase 1 silent-0-reads bug from the start this time.
- `deseq2` — same package set as Phase 1 (DESeq2, tximport, apeglm,
  ggplot2). Confirmed DESeq2 version 1.50.2, identical to the Mac build.

**Pre-existing HPC modules checked:** `sratoolkit/12Dec2024`,
`star/2.7.11b` (the buggy version — avoided, used conda-installed
2.7.10b instead), `samtools/1.21`, `fastqc/0.12.1`, `miniconda3`,
`anaconda3`. No modules existed for fastp, multiqc, deeptools, qualimap,
gffread, or salmon — installed via conda instead, for full consistency
with the Phase 1 toolset.

**Gotcha: dropped SSH connections kill interactive jobs.** Lost an
in-progress `conda env create` mid-install when the SSH connection to
the login node dropped unexpectedly, which also killed the `srun`
interactive session it was running in. In my experience this mostly
happens when not connected via the university's own wifi/network —
worth connecting via campus wifi or VPN when running long interactive
jobs if possible. More importantly: **running long jobs inside `tmux`
solves this properly** — a tmux session persists on the login node
independent of your SSH connection, so a dropped connection no longer
kills the job; just reconnect and `tmux attach -t <session_name>` to
pick back up exactly where you left off. Adopted this for all
long-running interactive work for the rest of Phase 2.

**Partial environment cleanup:** the dropped-connection failure left a
broken partial `rna-seq` env directory on disk, which `conda env list`
didn't show as registered but `conda env create` still refused to
overwrite (`CondaValueError: prefix already exists`). Fixed with
`conda env remove -n rna-seq` before rebuilding cleanly.

## Dataset

- GEO/SRA accession: GSE52778 ("airway" dataset), SRP033351 / PRJNA229998
- Comparison being tested: dexamethasone-treated vs. untreated, 4 paired
  human airway smooth muscle cell lines (8 samples total)
- Design: paired by cell line/donor (N61311, N052611, N080611, N061011)
  — plan to use `~cell + treatment` (or `~donor + condition`) as the
  DESeq2 design formula, controlling for donor effects, per CebolaLab's
  tutorial recommendation for paired designs
- Read lengths: uniformly 63bp raw across all 8 samples (confirmed via
  FastQC), 62bp after fastp trimming — will use `--sjdbOverhang 61` for
  STAR genome indexing

## Dataset download (airway, GSE52778)

Downloaded all 8 samples via SLURM batch job (`scripts/08_download_airway.sh`)
using `prefetch` + `fasterq-dump` from `sra-tools`.

**Critical bug found: `--split-files` silently produces mismatched R1/R2
pairs.** After downloading all 8 samples, verified R1/R2 read-count parity
for each (`zcat file.fastq.gz | wc -l`, divided by 4). **4 of 8 samples
(50%) had genuinely mismatched R1/R2 read counts** — not a download
corruption, but a real property of the underlying SRA data: these samples
contain a meaningful fraction of reads with a missing mate (likely a
technical artifact from how the original sequencing run or SRA deposit
handled certain reads). `--split-files` writes R1 and R2 independently
without enforcing synchronized pairing, silently producing files that
*look* valid (correct FASTQ format, consistent read length) but would
have fed misaligned read pairs directly into STAR — a serious,
hard-to-detect correctness bug that would not have thrown any error.

| Sample | Original R1 reads | Original R2 reads | Mismatch? |
|---|---|---|---|
| SRR1039508 | 22,935,521 | 22,935,521 | No |
| SRR1039509 | 21,155,707 | 21,155,707 | No |
| SRR1039512 | 28,136,282 | 28,136,282 | No |
| SRR1039513 | 16,823,088 | 43,356,464 | **Yes** |
| SRR1039516 | 27,298,970 | 30,043,024 | **Yes** |
| SRR1039517 | 34,298,260 | 34,298,260 | No |
| SRR1039520 | 21,275,888 | 34,575,286 | **Yes** |
| SRR1039521 | 23,487,860 | 41,152,075 | **Yes** |

**Fix:** re-downloaded the 4 affected samples using `--split-3` instead
of `--split-files`. `--split-3` guarantees R1/R2 contain only genuinely
paired reads (matched counts), and writes any unpaired/orphan reads to a
separate third file (`<SRR>.fastq`, no `_1`/`_2` suffix) rather than
silently corrupting the main pair files. Verified all 8 samples show
matched R1/R2 counts after the fix. Orphan-read files and `.sra` cache
directories were deleted after successful FASTQ extraction to reclaim
scratch space.

**Lesson learned:** always verify R1/R2 read-count parity immediately
after any SRA paired-end download, before trusting the data downstream —
`--split-files` can silently produce corrupted pairing for a substantial
fraction of real-world datasets (50% in this case), with no error message
at any stage. `--split-3` should be the default choice for paired-end SRA
downloads going forward, not `--split-files`.

## SLURM notes

- Partition(s) used: `short` (default partition, 2-day time limit) for
  general pipeline work; avoided `sharing` (1-hour limit, too short for
  most stages)
- Typical wait times: (fill in once you've submitted real jobs)
- Memory/time requested per stage vs. actually used: (fill in as you go)
- Gotcha: an `srun --pty` interactive session hit its own requested time
  limit mid-task and was cancelled automatically (`DUE TO TIME LIMIT`) —
  worth requesting more generous time limits for long-running interactive
  work, or switching to a submitted batch job (`sbatch`) with
  checkpointing for anything that might run long, rather than babysitting
  an interactive session.

## Pipeline run log

(mirror the same sections as phase1-notes.md)

### 1. Pre-alignment QC

Ran FastQC + MultiQC on all 8 raw samples (`scripts/09_airway_fastqc.sh`)
via SLURM batch job on the `short` partition. All 8 samples at 63bp read
length, ~48-50% GC, 46-57% duplication (expected/normal for RNA-seq —
reflects highly-expressed transcripts, not a quality problem), no
concerning FastQC flags.

### 2. Trimming

Ran fastp trimming (`scripts/10_airway_trim.sh`) via SLURM batch job on
the `short` partition. All 8 samples uniformly 62bp after trimming —
will use `--sjdbOverhang 61` for STAR genome indexing.

### 3. STAR genome indexing (GRCh38)
### 4. STAR alignment
### 5. Post-alignment QC
### 6. Salmon quantification
### 7. DESeq2 differential expression
### 8. Functional analysis

## Phase 1 vs Phase 2 comparison

| Stage | Phase 1 (laptop, Drosophila) | Phase 2 (HPCC, human) |
|---|---|---|
| Genome size | ~140Mb | ~3.1Gb |
| Index build time | | |
| Alignment time/sample | | |
| Peak memory used | | |
| New tools/skills needed | conda/bash | SLURM, module system |

## What was actually different at scale

-
