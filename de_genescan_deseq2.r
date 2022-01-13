library("DESeq2")
library("dplyr")

### Usage: de_genescan_deseq.r output_directory path_to_config path_to_count_file

# User defined variables 
compaxis <- "treatment"
args <- commandArgs(trailingOnly=TRUE)
outdir <- args[1]
config_file <- args[2]
count_file <- args[3]

# Function for defining DESeq2 design (might need to edit design depending on compaxis)
def_dds <- function(countTable,colTable) {
  DESeqDataSetFromMatrix(countData = countTable, colData = colTable, design = ~ treatment)
}

# Read in count data into one dataframe
config <- read.table(config_file,header=TRUE)
count_data <- data.frame(read.table(count_file,header=TRUE))

# Generate column data to insert into dds object
colTable <- config[-c(1:2)]
rownames(colTable) <- config$samples
compfact <- as.vector(unique(colTable$treatment))

# Generate pairwise comparisons for comparison axis
compvals <- matrix(nrow = sum(1:(length(compfact)-1)), ncol = 2)
iter = 1
for (i in 1:(length(compfact)-1)) {
  for (j in (i+1):length(compfact)) {
    compvals[iter,1] = compfact[i]
    compvals[iter,2] = compfact[j]
    iter = iter + 1
  }
}

# Find most expressed isoform for any gene
genes <- as.vector(unique(count_data$GeneID))
for (i in 1:(length(genes))) {
   temp_counts <- subset(count_data, count_data$GeneID == genes[i])
   temp_counts$colsum <- rowSums(temp_counts[,1:8])
   maxsum <- max(temp_counts$colsum)
   to_add <- subset(temp_counts, temp_counts$colsum == maxsum)
   if (exists('count_data_filt')) {
     count_data_filt[nrow(count_data_filt) + 1,] = to_add[1,]
   } else {
     count_data_filt <- to_add[1,]
   }
}

# Define DESeq2 objects
countTable <- count_data_filt[-c(9:11)]
dds <- def_dds(countTable,colTable)

# Do differential expression analysis and split up pairwise comparisons
# Write out results, MA plots
dds <- DESeq(dds)

for (i in 1:nrow(compvals)) {
  res <- results(dds, contrast = c(compaxis,compvals[i,2],compvals[i,1]))
  res_labeled <- data.frame(res, GeneID = count_data_filt$GeneID, TranscriptID = count_data_filt$TranscriptID)
  res_sorted <- res_labeled[order(res_labeled$padj),]
  
  write.table(as.data.frame(res_sorted),file=paste(outdir,"/deseq2_results_",compvals[i,1],"_",compvals[i,2],".txt", sep = ""),sep="\t",quote=FALSE,row.names = FALSE)
  
  png(paste(outdir,"/deseq2_maplot_",compvals[i,2],"_",compvals[i,1],".png", sep = ""),type='cairo')
  plotMA(res, alpha=0.05, main="DESeq2")
  dev.off()
  graphics.off()
}
