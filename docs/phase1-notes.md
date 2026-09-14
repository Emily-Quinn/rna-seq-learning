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

an FastQC on all 8 raw fastq.gz files (4 samples × R1/R2), then combined into one summary with MultiQC.

**Command:** `./scripts/01_fastqc.sh data/raw_fastq docs/qc_output`

**Key findings:**
- Adapter content: all 8 samples under 0.1% contamination — very clean data
- Overrepresented sequences: all 8 samples under 1% — no contamination artifacts
- Per-base sequence quality: consistent with expectations for Illumina Genome Analyzer II data (older platform, shorter 37bp reads)
- No red flags severe enough to warrant anything beyond standard trimming

Full report: [`docs/qc_output/multiqc_report.html`](qc_output/multiqc_report.html)

### 2. Trimming

Used fastp with default quality filtering and `--detect_adapter_for_pe` (paired-end auto adapter detection), minimum length 25bp.

| Sample | Condition | Reads passed filter | % passed | Duplication rate |
|---|---|---|---|---|
| GSM461177 | Untreated | 20,768,436 | ~98.2% | 13.2% |
| GSM461178 | Untreated | 20,875,258 | ~85.3% | 8.8% |
| GSM461180 | Treated | 21,057,766 | ~85.9% | 4.8% |
| GSM461181 | Treated | 24,678,922 | ~98.3% | 14.0% |

**Observation:** GSM461177 and GSM461181 showed high Read2 quality pre-trimming (Q20 ~92-95%), while GSM461178 and GSM461180 showed noticeably degraded Read2 quality (Q20 ~77%), leading to a much higher proportion of reads failing the quality filter (~28% vs ~2-3%). This split does **not** correlate with treatment condition (178 is untreated, 180 is treated), suggesting a batch, lane, or flow-cell effect rather than a biological one. fastp's filtering handled this cleanly — all samples still retained the large majority of reads. Worth keeping in mind during downstream QC (post-alignment mapping rates) to see if this pattern persists.

### Genome download

Initially attempted Ensembl release-116 (BDGP6.54) — URLs returned 404s across multiple naming patterns, including the `current_gtf` stable symlink path. Investigation revealed Ensembl underwent a major FTP restructuring in June 2026, retiring the old species-name-based FTP structure in favor of a new GCA/GCF-based structure at ftp.ebi.ac.uk.

Switched to **FlyBase** instead (the primary source for Drosophila annotations) — much simpler and more stable. Used release **r6.69**:
- Genome: `dmel-all-chromosome-r6.69.fasta.gz` (~146Mb uncompressed)
- Annotation: `dmel-all-r6.69.gtf.gz` (~79Mb uncompressed)

**Follow-up check:** also verified Ensembl's new GCA-based mirror (`ftp.ebi.ac.uk/pub/ensemblorganisms/GCA/000/001/215/4/flybase/2022_07/`) — it does host a genome + GTF for this assembly, with files dated as recently as April/May 2026, so it's an actively maintained mirror, not abandoned. However, the `2022_07` folder label reflects when Ensembl started tracking this particular annotation lineage, not necessarily which exact FlyBase release number the current file content corresponds to — there's no easy way to confirm it matches r6.69 specifically without downloading and inspecting the GTF header. Since we already had a confirmed, version-matched genome+GTF pair directly from FlyBase (the authoritative source), we stuck with that rather than switch.

Lesson: always verify genome/GTF download URLs before scripting a pipeline around them, and when using mirrors, be aware that folder/version labels don't always guarantee content currency — going to the primary source eliminates that ambiguity entirely.

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
