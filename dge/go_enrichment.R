# go_enrichment.R
#
# GO enrichment analysis for the pasilla (Drosophila) DESeq2 results,
# using clusterProfiler + org.Dm.eg.db.
#
# Inputs: sig_genes_full.csv (significant genes), all_tested_genes.csv
# (background universe) — already present in the repo root from
# dge_analysis.R's export step.

library(clusterProfiler)
library(org.Dm.eg.db)
library(enrichplot)
library(ggplot2)

## ---- 1. Load gene lists -------------------------------------------------

sig_genes <- read.csv("sig_genes_full.csv", row.names = 1)
all_genes <- read.csv("all_tested_genes.csv", row.names = 1)

# FlyBase IDs (e.g. "FBgn0000003") need no version-stripping, unlike
# GENCODE's Ensembl IDs in Phase 2.
sig_ids <- rownames(sig_genes)
background_ids <- rownames(all_genes)

cat("Significant genes:", length(sig_ids), "\n")
cat("Background universe:", length(background_ids), "\n")

## ---- 2. Run GO enrichment (Biological Process) --------------------------

ego <- enrichGO(
  gene          = sig_ids,
  universe      = background_ids,
  OrgDb         = org.Dm.eg.db,
  keyType       = "FLYBASE",
  ont           = "BP",          # Biological Process
  pAdjustMethod = "BH",
  pvalueCutoff  = 0.05,
  qvalueCutoff  = 0.05,
  readable      = TRUE           # converts FlyBase IDs to gene symbols in output
)

cat("GO terms enriched:", nrow(as.data.frame(ego)), "\n")

write.csv(as.data.frame(ego), "go_enrichment_results.csv", row.names = FALSE)

## ---- 3. Plots -------------------------------------------------------------

p_dot <- dotplot(ego, showCategory = 20) + ggtitle("GO Enrichment (Biological Process) - Pasilla Knockdown vs Control")
ggsave("go_dotplot.png", p_dot, width = 9, height = 8)

p_bar <- barplot(ego, showCategory = 20) + ggtitle("GO Enrichment (Biological Process) - Pasilla Knockdown vs Control")
ggsave("go_barplot.png", p_bar, width = 9, height = 8)

ego_sim <- pairwise_termsim(ego)
p_emap <- emapplot(ego_sim, showCategory = 20)
ggsave("go_enrichment_map.png", p_emap, width = 10, height = 9)

cat("GO enrichment complete. Results + plots written to working directory.\n")
