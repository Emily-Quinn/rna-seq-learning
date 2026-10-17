library(tximport)
library(DESeq2)
library(apeglm)

samples <- read.table("airway_samples.txt", header = TRUE, sep = "\t",
                       stringsAsFactors = FALSE)
tx2gene <- read.table("airway_tx2gene.txt", sep = "\t")

counts.imported <- tximport(
  files   = as.character(samples$path),
  type    = "salmon",
  tx2gene = tx2gene
)

colData <- data.frame(
  row.names = samples$sample_id,
  cell_line = factor(samples$cell_line),
  condition = factor(samples$condition)
)
colData$condition <- relevel(colData$condition, ref = "untreated")

dds <- DESeqDataSetFromTximport(
  counts.imported,
  colData = colData,
  design  = ~ cell_line + condition
)

dds <- DESeq(dds)
LFC <- lfcShrink(dds, coef = "condition_treated_vs_untreated", type = "apeglm")

LFC.gene <- as.data.frame(LFC)
LFC.sig  <- LFC.gene[!is.na(LFC.gene$padj) & LFC.gene$padj < 0.05, ]

write.csv(LFC.sig, "sig_genes_full.csv")
write.csv(LFC.gene, "all_tested_genes.csv")

cat("Exported", nrow(LFC.sig), "significant genes and", nrow(LFC.gene), "total tested genes.\n")
