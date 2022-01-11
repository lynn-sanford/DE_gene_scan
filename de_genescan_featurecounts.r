library("Rsubread")

# Load in config file with files for processing
args <- commandArgs(trailingOnly=TRUE)
gtf <- args[2]
outfile <- args[3]
out_annotation <- paste(strsplit(outfile,"[.]")[[1]][1],"_annotation.txt", sep="")
inputData <- read.table(args[1],header=TRUE)

# Transpose this file list and put it in a variable
fileList <- as.character(t(inputData$files))

# Sample list
sampleList <- as.character(t(inputData$samples))

# Load GTF file
gtf_table <- read.table(gtf)

# Run featurecounts
fc <- featureCounts(files=fileList,
    annot.ext=gtf,
    isGTFAnnotationFile=TRUE,
    GTF.featureType="gene_length",
    useMetaFeatures=FALSE,
    allowMultiOverlap=TRUE,
    largestOverlap=TRUE,
    countMultiMappingReads=FALSE,
    isPairedEnd=FALSE,
    strandSpecific=1,
    nthreads=8)
fc$annotation["TranscriptID"] <- gtf_table["V13"]

# Write out annotation and count data as tab delimited txt files
# Count data is just counts
# Annotation data has the gene length information for calculating TPM

counts_to_write <- data.frame(fc$counts)
colnames(counts_to_write) <- sampleList
counts_to_write["TranscriptID"] <- gtf_table["V13"]
counts_to_write["GeneID"] <- fc$annotation["GeneID"]

write.table(counts_to_write,file=outfile,append=FALSE,sep='\t',quote=FALSE,row.names=FALSE)
write.table(fc$annotation,file=out_annotation,append=FALSE,sep='\t',quote=FALSE,row.names=FALSE)
