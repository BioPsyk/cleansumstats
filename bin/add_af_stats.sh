#!/usr/bin/env bash

infile="${1}"
afFreqs="${2}"
outfile="${3}"

## Join with AF table using chrpos column add NA for missing fields
zcat ${infile} | tail -n+2 | awk -vOFS="\t" '{printf "%s%s", $1":"$2,OFS; for (i=1;i<NF;++i){printf "%s%s", $i, OFS}; print $NF}' | LC_ALL=C sort -k 1,1 | LC_ALL=C join -e "NA" -t "$(printf '\t')" -a 1 -1 1 -2 1 -o auto - <(awk -vOFS="\t" '{print $1,$4,$5,$6,$7,$8}' ${afFreqs}) | cut -f2- | cat <(zcat ${infile} | head -n1 | awk -vOFS="\t" '{print $0,"EAS","EUR","AFR", "AMR", "SAS"}') - | gzip -c > ${outfile}

