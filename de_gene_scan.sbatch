#!/bin/bash
#SBATCH --job-name=de_gene_scan      # Job name
#SBATCH --mail-type=END         # Mail events (NONE, BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=<email> # Where to send mail
#SBATCH --nodes=1
#SBATCH --ntasks=1              # Number of CPU (processer cores i.e. tasks)
#SBATCH --time=1:00:00         # Time limit hrs:min:sec
#SBATCH --partition=short
#SBATCH --mem=32gb               # Memory limit
#SBATCH --output=<path to out>
#SBATCH --error=<path to err>


##### OUTPUT RUN PARAMETERS #######################

# Calculate the number of processors allocated to this run.
NPROCS=$SLURM_CPUS_ON_NODE

# Display the job context
echo Running on host `hostname`
echo Time is `date`
echo Directory is `pwd`
echo Using ${NPROCS} processors

##### LOAD MODULES ##############

module load python/3.6.3
module load bedtools/2.28.0
module load R/3.6.1
export R_LIBS_USER=/Users/lysa8537/.R/packages

##### SPECIFY VARIABLES ###########################

input='fiji.colorado.edu:/projects/dowellLab/sasse/Sasse2019/GRO-seq/mapped/bams/B2B30GRO'
scratch=/scratch/Users/lysa8537/gerber_snp_analysis
output=/Users/lysa8537/projects/gerber_snp_analysis/de_gene_scan
script=/Users/lysa8537/projects/gerber_snp_analysis/scripts
timepoint_min=30
gtf=/Users/lysa8537/data/annotation/hg38/hg38_refseq_diff53prime.gtf
deconfig=/Users/lysa8537/projects/gerber_snp_analysis/processing_files/de_genescan_GRO30.txt
samp="snp_manual_bidir"
comp="vehicle_dex"
tfit=/Users/lysa8537/projects/gerber_snp_analysis/manual_bidir_annotation_4col.bed
chrom=/scratch/Shares/dowell/genomes/hg38/hg38.chrom.sizes

###################################################

# Make directories and define outfile names
mkdir -p "$scratch"
mkdir -p "$scratch"/bams
mkdir -p "$scratch"/de_gene_scan
mkdir -p "$scratch"/de_gene_scan/proc_files
mkdir -p "$scratch"/de_gene_scan/deseq_results
mkdir -p "$scratch"/de_gene_scan/featurecounts_results
mkdir -p "$output"
gtf_filename=$(basename "$gtf" .gtf)
gtf_outfile="$scratch"/de_gene_scan/proc_files/"$gtf_filename"_"$timepoint_min"min.gtf
fc_filename="$scratch"/de_gene_scan/featurecounts_results/fc_counts.txt

# Sync bam files to scratch
#rsync "$input"*.bam "$scratch"/bams

# Make timepoint-specific GTF file
sh timepoint_gtf_manip.sh "$gtf" "$timepoint_min" "$gtf_outfile"

# Run featurecounts
Rscript "$script"/de_genescan_featurecounts.r "$deconfig" "$gtf_outfile" "$fc_filename"

# Run DESeq2
Rscript "$script"/de_genescan_deseq2.r "$scratch"/de_gene_scan/deseq_results "$deconfig" "$fc_filename"

# Run python script
python3 "$script"/gene_scan.py -i "$tfit" -c "$chrom" -s "$samp" -o "$scratch"/de_gene_scan \
    -g "$gtf" -d "$scratch"/de_gene_scan/deseq_results/deseq2_results_"$comp".txt \
    -t 1000 -w 1000000 --sig -p 0.05

# Sync to output directory
rsync -ar "$scratch"/de_gene_scan/* "$output"/

#Final time stamp
echo Time is `date`
