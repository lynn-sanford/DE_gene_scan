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
export R_LIBS_USER=<R library path>

##### SPECIFY VARIABLES ###########################

input=<path to input directory> # Source of BAM/CRAM (if CRAM need to add a samtools conversion step to convert to BAM)
scratch=<path to scratch dir>
output=<path to output dir>
script=<path to script dir (this repository)>
timepoint_min=30 # Timepoint for cutting gtf file gene lengths to reflect PolII processivity
gtf="$script"/hg38_refseq_diff53prime.gtf
deconfig=<path to config file>
samp="" # Sample name for output files
comp="" # DESeq comparison to use - must match the pattern "cond1_cond2" with conditions from DE config file
tfit=<path to bedfile of regions>
chrom=<path to chromosome size file>

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
rsync "$input"*.bam "$scratch"/bams

# Make timepoint-specific GTF file
sh "$script"/timepoint_gtf_manip.sh "$gtf" "$timepoint_min" "$gtf_outfile"

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
