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
| 13 | Functional analysis: GO enrichment (GoSeq) | 2–3 hrs | Optional stretch goal. **Actual: used clusterProfiler + org.Dm.eg.db instead** — more modern tooling, better documentation/visualization, at the tradeoff of not correcting for RNA-seq gene-length bias the way GoSeq does. |
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
| 2 | Write SLURM batch scripts for each stage (this is new vs. Phase 1) | Needs `#SBATCH` headers: partition, time, mem, cpus. **Actual: scripts were written incrementally, one per stage as each was reached**, rather than all upfront — made more sense once actual resource needs for each step became clearer through doing earlier steps. |
| 3 | Choose + download a real human dataset with a clear 2-group comparison | e.g. a public GEO dataset with disease vs. healthy or treated vs. untreated. **Actual: done before GRCh38 download/index** (reordered from original plan) — chose the "airway" dataset (GSE52778), the standard human DESeq2/tximport teaching dataset, for the same reference-validation rationale as Phase 1's pasilla choice. |
| 4 | Download/index GRCh38 (request enough mem: 32–64GB) | This step alone can take a few hours. **Actual: ~56 min at 64GB requested, 51.86GB peak used** — see docs/phase2-notes.md comparison table. |
| 5 | Run full pipeline as batch jobs | Alignment per sample may take 30 min–a few hours depending on job resources |
| 6 | DESeq2 analysis (can run locally on laptop once counts are downloaded — much smaller than raw data) | **Actual: ran directly on Explorer instead**, in the same `deseq2` conda environment used throughout Phase 2 — simpler than transferring quant.sf files back to a laptop, and kept the whole Phase 2 pipeline self-contained on the cluster. |
| 7 | Compare Phase 1 vs Phase 2 experience in writeup: what changed at scale, what new problems (queueing, storage quotas, walltime limits) came up | |

Rough time budget: **1–3 weeks**, gated more by HPCC queue times and
learning SLURM than by pipeline complexity itself, since you'll have already
solved the "what does each command do" problem in Phase 1.

## Log

Use this section (or docs/phase1-notes.md / phase2-notes.md) to jot dated
notes as you go — useful both for debugging later and for turning into a
GitHub-friendly writeup. High-level milestones below; full detail in the
docs/ notes files. Reconstructed from git commit history.

- `2026-09-08`: Phase 1 project scaffold created.
- `2026-09-10` to `2026-09-14`: environment setup, raw QC (FastQC/MultiQC),
  fastp trimming for all 4 pasilla samples; Ensembl FTP restructuring
  documented.
- `2026-09-21` to `2026-09-24`: STAR 2.7.11b silent 0-reads bug found and
  fixed (pinned 2.7.10b); alignment, post-alignment QC, bigwig/IGV
  visualization, and Salmon quantification completed for all 4 samples;
  `07_salmon_quant.sh` brace bug found and fixed.
- `2026-09-26`: DESeq2 differential expression run; pasilla knockdown
  confirmed (log2FC -2.09, padj 1.33e-70). Explorer cluster name
  corrected (was mistakenly called "Discovery").
- `2026-09-28`: Phase 2 dataset chosen — airway (GSE52778).
- `2026-10-01`: Phase 2 started on Explorer HPC — conda environments
  built, tmux/SSH/quota lessons documented.
- `2026-10-05`: `fasterq-dump` pairing bug found and fixed — 4 of 8
  airway samples had silently mismatched R1/R2 read counts
  (`--split-files` -> `--split-3`).
- `2026-10-06`: airway samples QC'd and trimmed; GRCh38 (GENCODE v46)
  downloaded and indexed via SLURM (~56 min, 28GB index).
- `2026-10-07`: all 8 airway samples aligned (STAR job array),
  post-alignment QC'd, and quantified with Salmon; CRISPLD2 induction
  confirmed (log2FC +2.61, padj 1.45e-44), matching Himes et al. 2014.
  DESeq2 (paired `~cell_line + condition` design) run same day.
- `2026-10-16` to `2026-10-17`: GO enrichment (clusterProfiler) completed
  for both phases — airway showed coherent glucocorticoid-pathway
  biology; pasilla surfaced metabolic rather than splicing signatures
  (see phase1-notes.md for discussion). Phase 1/Phase 2 comparison table,
  README Key Results section, embedded figures, and PLAN.md deviation
  notes finalized, closing out the project.

**Elapsed calendar time:** ~6 weeks (Sept 8 - Oct 17), spanning Phase 1's
full local pipeline, Phase 2's full HPC pipeline, and functional analysis
for both — longer than the original ~3-5 day (Phase 1) + 1-3 week
(Phase 2) estimates, largely due to real debugging detours (4 major bugs
found and fixed across both phases) and working around other
commitments rather than in continuous focused blocks.
