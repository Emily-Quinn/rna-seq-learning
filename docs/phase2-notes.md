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

- Partition(s) used:
- Typical wait times:
- Memory/time requested per stage vs. actually used:

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
