# 17_airway_go_enrichment.R
#
# GO enrichment analysis for the airway (dexamethasone) DESeq2 results,
# using clusterProfiler + org.Hs.eg.db.
#
# Inputs: sig_genes_full.csv (significant genes), all_tested_genes.csv
# (background universe) from export_sig_genes_airway.R

library(clusterProfiler)
library(org.Hs.eg.db)
library(enrichplot)
library(ggplot2)

## ---- 1. Load gene lists -------------------------------------------------

sig_genes <- read.csv("sig_genes_full.csv", row.names = 1)
all_genes <- read.csv("all_tested_genes.csv", row.names = 1)

# Strip GENCODE version suffixes (e.g. "ENSG00000103196.12" -> "ENSG00000103196")
# org.Hs.eg.db expects unversioned Ensembl IDs.
sig_ids <- sub("\\.\\d+$", "", rownames(sig_genes))
background_ids <- sub("\\.\\d+$", "", rownames(all_genes))

cat("Significant genes:", length(sig_ids), "\n")
cat("Background universe:", length(background_ids), "\n")

## ---- 2. Run GO enrichment (Biological Process) --------------------------

ego <- enrichGO(
  gene          = sig_ids,
  universe      = background_ids,
  OrgDb         = org.Hs.eg.db,
  keyType       = "ENSEMBL",
  ont           = "BP",          # Biological Process
  pAdjustMethod = "BH",
  pvalueCutoff  = 0.05,
  qvalueCutoff  = 0.05,
  readable      = TRUE           # converts Ensembl IDs to gene symbols in output
)

cat("GO terms enriched:", nrow(as.data.frame(ego)), "\n")

write.csv(as.data.frame(ego), "go_enrichment_results.csv", row.names = FALSE)

## ---- 3. Plots -------------------------------------------------------------

p_dot <- dotplot(ego, showCategory = 20) + ggtitle("GO Enrichment (Biological Process) - Airway, Dex vs Untreated")
ggsave("go_dotplot.png", p_dot, width = 9, height = 8)

p_bar <- barplot(ego, showCategory = 20) + ggtitle("GO Enrichment (Biological Process) - Airway, Dex vs Untreated")
ggsave("go_barplot.png", p_bar, width = 9, height = 8)

# Enrichment map (shows relationships between enriched terms)
ego_sim <- pairwise_termsim(ego)
p_emap <- emapplot(ego_sim, showCategory = 20)
ggsave("go_enrichment_map.png", p_emap, width = 10, height = 9)

cat("GO enrichment complete. Results + plots written to working directory.\n")
