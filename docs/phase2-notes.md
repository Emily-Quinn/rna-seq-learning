# Phase 2 Notes — Full-Scale Pipeline (Human genome, Northeastern HPCC)

## Setup

- Date started:
- Explorer cluster account/access notes:
- Modules available vs. built manually:

## Dataset

- GEO/SRA accession: GSE52778 ("airway" dataset), SRP033351 / PRJNA229998
- Comparison being tested: dexamethasone-treated vs. untreated, 4 paired
  human airway smooth muscle cell lines (8 samples total)
- Design: paired by cell line/donor (N61311, N052611, N080611, N061011)
  — plan to use `~cell + treatment` (or `~donor + condition`) as the
  DESeq2 design formula, controlling for donor effects, per CebolaLab's
  tutorial recommendation for paired designs
- Read lengths vary by sample (87-126bp per run) — unlike Phase 1's
  uniform 36bp, will need per-sample or max-based `--sjdbOverhang` for
  STAR indexing

## SLURM notes

## Setup

- Date started: (fill in your actual date)
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
kills the job; just reconnect and `tmux attach -s <session_name>` to
pick back up exactly where you left off. Adopted this for all
long-running interactive work for the rest of Phase 2.

**Partial environment cleanup:** the dropped-connection failure left a
broken partial `rna-seq` env directory on disk, which `conda env list`
didn't show as registered but `conda env create` still refused to
overwrite (`CondaValueError: prefix already exists`). Fixed with
`conda env remove -n rna-seq` before rebuilding cleanly.

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
### 2. Trimming
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
