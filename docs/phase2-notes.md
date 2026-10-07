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

Downloaded GENCODE release 46 (GRCh38.p14) primary assembly genome fasta
(~3.0GB) and comprehensive GTF annotation (~1.6GB uncompressed) directly
from GENCODE's FTP. Verified: 194 sequences in the fasta (chromosomes +
unplaced/unlocalized scaffolds), consistent with expected GRCh38 primary
assembly structure.

Built the STAR index (`scripts/11_airway_star_index.sh`) via SLURM batch
job: 8 threads, 64GB RAM requested, 8-hour time limit. No
`--genomeSAindexNbases` override (default 14 is correct for a genome
this large, unlike Phase 1's small-genome override). `--sjdbOverhang 61`
(62bp trimmed reads − 1).

**Result:** completed successfully in ~56 minutes (20:00:55-20:56:35).
Index size: 28GB on disk. STAR version confirmed 2.7.10b throughout (the
correct pinned version — avoided the Phase 1 2.7.11b bug from the start
this time).

### 4. STAR alignment

Aligned all 8 samples via SLURM job array (`scripts/12_airway_star_align.sh`,
`--array=0-7`) — 8 threads/48GB RAM per task, up to 5 tasks running in
parallel on the `short` partition (remaining 3 queued automatically until
resources freed up).

**Result:** all 8 samples aligned successfully, no errors.

| Sample | Input reads | Uniquely mapped % | Multi-mapped % |
|---|---|---|---|
| SRR1039508 | 22,445,289 | 94.18% | 4.50% |
| SRR1039509 | 20,517,083 | 93.85% | 4.28% |
| SRR1039512 | 27,196,274 | 95.20% | 4.05% |
| SRR1039513 | 16,091,880 | 95.29% | 3.89% |
| SRR1039516 | 26,123,507 | 94.98% | 4.22% |
| SRR1039517 | 32,871,045 | 95.48% | 3.90% |
| SRR1039520 | 20,370,846 | 95.15% | 4.01% |
| SRR1039521 | 22,416,611 | 95.18% | 3.98% |

Notably higher and more consistent uniquely-mapped rates than Phase 1's
pasilla data (79.6-85.0%) — expected, given GENCODE's human annotation is
far more mature/comprehensive than FlyBase's, and this is well-established
published data.

### 5. Post-alignment QC

Ran post-alignment QC via SLURM job array (`scripts/13_airway_post_align_qc.sh`,
`--array=0-7`) — sort/index BAMs, `samtools flagstat`, qualimap `bamqc` +
`rnaseq`. 4 threads/24GB RAM per task, up to 5 tasks in parallel on `short`.

**Percent reads mapped to exons (qualimap rnaseq):**

| Sample | % mapped to exons |
|---|---|
| SRR1039508 | 94.58% |
| SRR1039509 | 94.65% |
| SRR1039512 | 94.47% |
| SRR1039513 | 95.21% |
| SRR1039516 | 94.12% |
| SRR1039517 | 94.42% |
| SRR1039520 | 94.28% |
| SRR1039521 | 95.04% |

Tightly consistent (94.12-95.21%) across all 8 samples — comparable to
Phase 1's pasilla results (96.48-97.31%), confirming high-quality,
well-prepared RNA-seq libraries with minimal genomic DNA contamination.

**samtools flagstat:** all 8 samples show ~100% properly paired reads;
only SRR1039508 and SRR1039509 (the two samples never affected by the
Phase 2 `--split-3` pairing fix) show a negligible number of singletons
(61 and 72 respectively, out of tens of millions of reads) — expected,
normal at this scale.

### 6. Salmon quantification

Built transcriptome fasta from GENCODE v46 GTF (`scripts/14_airway_build_transcriptome.sh`)
— 254,129 transcripts extracted (vs. Phase 1's 35,747 Drosophila
transcripts), 456MB fasta.

Quantified all 8 samples (`scripts/15_airway_salmon_quant.sh`, SLURM job
array, all 8 tasks ran in parallel) against their
`Aligned.toTranscriptome.out.bam` files from the STAR alignment step.
All 8 completed quickly (a few minutes), no errors.

**Spot-check: CRISPLD2 (ENSG00000103196), the glucocorticoid-responsive
gene identified in the original Himes et al. 2014 publication this
dataset comes from.** Summed TPM across its 6 known transcript isoforms (ENST00000262424, ENST00000563066, ENST00000564567, ENST00000566151,
ENST00000566165, ENST00000566789):

| Sample | Condition | Summed TPM (CRISPLD2) |
|---|---|---|
| SRR1039508 | untreated | 13.3 |
| SRR1039512 | untreated | 14.9 |
| SRR1039516 | untreated | 13.4 |
| SRR1039520 | untreated | 14.3 |
| SRR1039509 | treated (dex) | 107.8 |
| SRR1039513 | treated (dex) | 106.7 |
| SRR1039517 | treated (dex) | 44.7 |
| SRR1039521 | treated (dex) | 104.3 |

Untreated samples cluster tightly (~13-15 TPM); three of four treated
samples show ~8x induction (~105-108 TPM), with the fourth (SRR1039517)
showing a smaller but still clear ~3x induction — consistent with
expected donor-to-donor variability, which the planned `~cell +
treatment` paired DESeq2 design formula should properly account for.
Strong independent confirmation the pipeline is producing correct,
biologically meaningful results, matching the direction and gene
identity reported in the original published study.

### 7. DESeq2 differential expression

Built `airway_samples.txt` (sample sheet with cell_line + condition) and
`airway_tx2gene.txt` (transcript-to-gene mapping, 254,129 entries,
extracted directly from GENCODE's GTF using the standard `transcript`
feature type — simpler than Phase 1's FlyBase `mRNA`/non-coding-type
workaround, since GENCODE uses standard GTF conventions).

Ran DESeq2 (`dge_airway/dge_analysis_airway.R`) with a **paired design**
(`~cell_line + condition`), controlling for donor-to-donor variability
across the 4 matched cell lines — an upgrade from Phase 1's simpler
`~condition` design, appropriate given airway's matched-pairs structure.
Explicitly releveled `condition` with `untreated` as reference from the
start (learned from Phase 1), so the coefficient
`condition_treated_vs_untreated` was correct on the first run with no
rediscovery needed.

**Result:**

| Metric | Value |
|---|---|
| Genes tested (nonzero counts) | 32,302 |
| Significant (padj<0.05) | 3,574 |
| Significant + large effect (padj<0.05, \|log2FC\|>2) | 198 |
| Up in treated | 1,967 (6.1%) |
| Down in treated | 1,607 (5%) |
| Low-count filtered | 15,464 (48%) |

3,574 significant genes is substantial but biologically plausible —
dexamethasone (a glucocorticoid) has broad transcriptional effects across
inflammation, metabolism, and immune signaling pathways, consistent with
published literature on corticosteroid response.

**CRISPLD2 (ENSG00000103196) confirmed — the key validation, matching
both the manual TPM spot-check and the original publication's finding:**

| Gene | baseMean | log2FoldChange | pvalue | padj |
|---|---|---|---|---|
| ENSG00000103196.12 (CRISPLD2) | 2995.6 | +2.61 | 4.13e-47 | 1.45e-44 |

A log2FC of +2.61 corresponds to a ~6.1-fold increase in treated samples
— closely matching the ~3-8x induction independently estimated from raw
Salmon TPM summation earlier, and correctly **positive** (induced, not
suppressed), matching the direction reported in Himes et al. 2014 — the
original publication this dataset comes from. This closes the same
validation loop as Phase 1 (visual/manual check + rigorous statistical
model, both agreeing on direction and magnitude, both matching known
published biology), this time at the scale of a real human RNA-seq
dataset with donor-level replication.

**Key plots:** see `dge_airway/results/` — `pca_plot.png` (colored by
condition, shaped by cell line — check whether samples cluster primarily
by treatment or by donor), `volcano_plot.png`, `ma_plot.png`,
`pvalue_hist.png`, `fdr_hist.png`.

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
