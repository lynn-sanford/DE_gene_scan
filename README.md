# DE\_gene\_scan
Pipeline to scan for differentially expressed genes around specific genomic coordinates

This repository consists of several related scripts to process nascent data to find differentially expressed genes around specific genomic or transcriptomic features (such as eRNAs)

The provided SBATCH script connects the scripts for usage with a HPC slurm scheduler.

Each script has individual usage information, but as an overview:

## timepoint\_gtf\_manip.sh
Bash script truncates genes in a gtf file to reflect the processivity of PolII at a specific timepoint
Usage: sh timepoint\_gtf\_manip.sh input\_gtf\_file truncation\_timepoint outfile\_name
Example input GTF file provided (hg38\_refseq\_diff53prime.gtf)

## de\_genescan\_featurecounts.r
R script to run featurecounts with modified GTF file. Requires config file.
Usage: Rscript de\_genescan\_featurecounts.r path\_to\_config path\_to\_gtf outfile\_name
Example config file provided (de\_config\_example.txt)

## de\_genescan\_deseq.r
R script to run DESeq2 on counts from featurecounts. Requires same config file as featurecounts script.
Usage: Rscript de\_genescan\_deseq.r output\_directory path\_to\_config path\_to\_count\_file

## gene\_scan.py
Python script to take in feature file (such as output from tfit) and gene DE information and output file containing regions and nearby genes
Usage: python3 gene\_scan.py -h

## Config file
R scripts require a config file defining input bam files, sample names, and treatment conditions for DE analysis. An example is provided (de\_config\_example.txt)
