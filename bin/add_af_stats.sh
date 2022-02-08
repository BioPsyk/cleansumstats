#!/usr/bin/env bash

infile="${1}"
afFreqs="${2}"
emod="${3}"
outfile="${4}"

## Join with AF table using chrpos column add NA for missing fields
zcat ${infile} | tail -n+2 | awk -vOFS="\t" '{printf "%s%s", $1":"$2,OFS; for (i=1;i<NF;++i){printf "%s%s", $i, OFS}; print $NF}' | LC_ALL=C sort -k 1,1 | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 <(zcat ${emod}) - | LC_ALL=C join -e "NA" -t "$(printf '\t')" -a 1 -1 1 -2 1 -o auto - <(awk -vOFS="\t" '{print $1,$4,$5,$6,$7,$8}' ${afFreqs}) | LC_NUMERIC=POSIX awk -vFS="\t" -vOFS="\t" '{if($2=="1" || $2=="NA"){print $0}else{for (i=1;i<14;++i){printf "%s%s", $i, OFS};for (i=14;i<18;++i){printf "%s%s", 1-$i, OFS}; print 1-$18}}' | cut -f3- | cat <(zcat ${infile} | head -n1 | awk -vOFS="\t" '{print $0,"EAS","EUR","AFR", "AMR", "SAS"}') - | gzip -c > ${outfile}

