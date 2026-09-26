library(tximport)
library(DESeq2)

samples <- read.table("samples.txt", header = TRUE, sep = "\t", stringsAsFactors = FALSE)
tx2gene <- read.table("tx2gene.txt", sep = "\t")

counts.imported <- tximport(
  files   = as.character(samples$path),
  type    = "salmon",
  tx2gene = tx2gene
)

colData <- data.frame(
  row.names = samples$sample_id,
  condition = factor(samples$condition)
)
colData$condition <- relevel(colData$condition, ref = "untreated")

dds <- DESeqDataSetFromTximport(counts.imported, colData = colData, design = ~condition)
dds <- DESeq(dds)
print(resultsNames(dds))
