#!/bin/bash
### timepoint_gtf_manip.sh
### Usage: timepoint_gtf_manip.sh input_gtf_file truncation_timepoint outfile_name
### Input must be in gtf format
### Truncation timepoint defines max length of gene in outfile to reflect processivity of PolII

# Read in input variables
infile=$1
timepoint=$2
let proc="$timepoint"*3000
outfile=$3

# Process + strand genes
awk -v proc="$proc" \
    '{FS=OFS="\t"}; {if ($7 == "+" && $5 > ($4+proc)) print $1,$2,$3,$4,($4+proc),$6,$7,$8,$9}' \
    "$infile" > "$outfile".temp
awk -v proc="$proc" \
    '{FS=OFS="\t"}; {if ($7 == "+" && $5 <= ($4+proc)) print $0}' \
    "$infile" >> "$outfile".temp

# Process - strand genes
awk -v proc="$proc" \
    '{FS=OFS="\t"}; {if ($7 == "-" && $4 < ($5-proc)) print $1,$2,$3,($5-proc),$5,$6,$7,$8,$9}' \
    "$infile" >> "$outfile".temp
awk -v proc="$proc" \
    '{FS=OFS="\t"}; {if ($7 == "-" && $4 >= ($5-proc)) print $0}' \
    "$infile" >> "$outfile".temp

sort -k1,1 -k4,4n "$outfile".temp > "$outfile"

rm "$outfile".temp
