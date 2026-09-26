# Phase 2 Notes — Full-Scale Pipeline (Human genome, Northeastern HPCC)

## Setup

- Date started:
- Explorer cluster account/access notes:
- Modules available vs. built manually:

## Dataset

- GEO/SRA accession:
- Comparison being tested:

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
