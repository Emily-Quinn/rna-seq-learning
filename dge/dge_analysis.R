# dge_analysis.R
#
# Differential gene expression analysis with DESeq2, following the
# CebolaLab/RNA-seq pipeline. Run this after Salmon quantification.
#
# Expects (edit paths as needed):
#   - samples.txt        : tab-delimited, columns = sample_id, path_to_quant_sf, condition
#   - tx2gene.txt         : tab-delimited transcript-to-gene mapping for your annotation
#
# Install deps once:
#   BiocManager::install(c("DESeq2", "tximport", "apeglm", "biomaRt"))

library(tximport)
library(DESeq2)
library(apeglm)
library(ggplot2)

## ---- 1. Import sample sheet + counts ----------------------------------

samples <- read.table("samples.txt", header = TRUE, sep = "\t",
                       stringsAsFactors = FALSE)
# expected columns: sample_id, path, condition  (add batch/donor col if needed)

tx2gene <- read.table("tx2gene.txt", sep = "\t")

counts.imported <- tximport(
  files   = as.character(samples$path),
  type    = "salmon",
  tx2gene = tx2gene
)

## ---- 2. Build DESeq2 dataset ------------------------------------------

colData <- data.frame(
  row.names = samples$sample_id,
  condition = factor(samples$condition)
  # add: batch = factor(samples$batch)  if you have a batch/donor covariate
)

dds <- DESeqDataSetFromTximport(
  counts.imported,
  colData = colData,
  design  = ~condition          # e.g. ~ batch + condition if controlling for batch
)

dds <- DESeq(dds)
resultsNames(dds)                # inspect available coefficients
plotDispEsts(dds)

## ---- 3. Differential expression + shrinkage ---------------------------

# Replace "condition_treated_vs_untreated" with the actual coefficient name
# from resultsNames(dds) above.
LFC <- lfcShrink(dds, coef = "condition_treated_vs_untreated", type = "apeglm")

summary(LFC, alpha = 0.05)

n_sig <- sum(!is.na(LFC$padj) & LFC$padj < 0.05)
n_sig_2fold <- sum(!is.na(LFC$padj) & LFC$padj < 0.05 & abs(LFC$log2FoldChange) > 2)
cat("Significant genes (padj<0.05):", n_sig, "\n")
cat("Significant genes (padj<0.05, |log2FC|>2):", n_sig_2fold, "\n")

## ---- 4. QC plots -------------------------------------------------------

theme_qc <- theme(
  panel.background = element_blank(),
  panel.border     = element_rect(fill = NA),
  plot.title       = element_text(hjust = 0.5)
)

# PCA
vst.r <- vst(dds, blind = TRUE)
pca_data <- plotPCA(vst.r, intgroup = "condition", returnData = TRUE)
p_pca <- ggplot(pca_data, aes(PC1, PC2, color = condition)) +
  geom_point(size = 3) + theme_qc + ggtitle("PCA - sample clustering")
ggsave("pca_plot.png", p_pca, width = 6, height = 5)

# MA plot
png("ma_plot.png", width = 800, height = 600)
plotMA(LFC, main = "MA plot: treated vs untreated", cex = 0.5)
dev.off()

# p-value / FDR distributions
png("pvalue_hist.png", width = 800, height = 600)
hist(LFC$pvalue, breaks = 50, col = "grey",
     main = "p-value distribution", xlab = "p-value")
dev.off()

png("fdr_hist.png", width = 800, height = 600)
hist(LFC$padj, breaks = 50, col = "grey",
     main = "FDR distribution", xlab = "Adjusted p-value")
dev.off()

# Volcano plot
lfc_thresh  <- 2
pval_thresh <- 0.05

volcano_df <- data.frame(
  logFC      = LFC$log2FoldChange,
  negLogPval = -log10(LFC$padj)
)
sig <- with(volcano_df, abs(logFC) > lfc_thresh & negLogPval > -log10(pval_thresh))

png("volcano_plot.png", width = 800, height = 600)
plot(volcano_df, pch = 16, cex = 0.4,
     xlab = expression(log[2] ~ fold ~ change),
     ylab = expression(-log[10] ~ pvalue),
     main = "Volcano plot: treated vs untreated")
points(volcano_df[sig, ], pch = 16, cex = 0.5, col = "red")
abline(h = -log10(pval_thresh), col = "green3", lty = 2)
abline(v = c(-lfc_thresh, lfc_thresh), col = "blue", lty = 2)
dev.off()

## ---- 5. Top genes table -------------------------------------------------

LFC.gene <- as.data.frame(LFC)
LFC.sig  <- LFC.gene[!is.na(LFC.gene$padj) & LFC.gene$padj < 0.05, ]

top10_padj <- head(LFC.sig[order(LFC.sig$padj), ], 10)
top10_lfc  <- head(LFC.sig[order(abs(LFC.sig$log2FoldChange), decreasing = TRUE), ], 10)

write.csv(top10_padj, "top10_by_padj.csv")
write.csv(top10_lfc,  "top10_by_foldchange.csv")

cat("Analysis complete. Plots + tables written to working directory.\n")
