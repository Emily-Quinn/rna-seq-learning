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

# Note: tx2gene/gene rownames carry GENCODE version suffixes (e.g. ".12")
# so match by prefix rather than exact string.
target <- grep("^ENSG00000103196", rownames(LFC.gene), value = TRUE)
print(LFC.gene[target, ])
