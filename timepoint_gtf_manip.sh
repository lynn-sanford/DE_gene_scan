#!/bin/bash

timepoint=$2
let proc="$timepoint"*3000
infile=$1
outfile=$3

awk -v proc="$proc" \
    '{FS=OFS="\t"}; {if ($7 == "+" && $5 > ($4+proc)) print $1,$2,$3,$4,($4+proc),$6,$7,$8,$9}' \
    "$infile" > "$outfile".temp
awk -v proc="$proc" \
    '{FS=OFS="\t"}; {if ($7 == "+" && $5 <= ($4+proc)) print $0}' \
    "$infile" >> "$outfile".temp
awk -v proc="$proc" \
    '{FS=OFS="\t"}; {if ($7 == "-" && $4 < ($5-proc)) print $1,$2,$3,($5-proc),$5,$6,$7,$8,$9}' \
    "$infile" >> "$outfile".temp
awk -v proc="$proc" \
    '{FS=OFS="\t"}; {if ($7 == "-" && $4 >= ($5-proc)) print $0}' \
    "$infile" >> "$outfile".temp
sort -k1,1 -k4,4n "$outfile".temp > "$outfile"

rm "$outfile".temp
