#!/usr/bin/env bash

ACOR=${1}
STAT=${2}

#Prepare from ACOR the data not modified
cat $ACOR \
  | sed 's/[[:space:]]*$//' \
  | awk -vFS="\t" -vOFS="\t" 'NR==1{printf "%s%s%s%s%s%s%s%s%s%s%s", $1,OFS, "CHR",OFS, "POS",OFS, $5,OFS, $6,OFS, $7; for(i=9; i<NF; i++){printf "%s%s", OFS, $i}; if(NF != 8){ printf "%s%s", OFS,$NF }else{printf "%s","\n"}} NR>1{split($4,out,":"); for(i=9; i<=NF; i++){$i=$i*$8}; printf "%s%s%s%s%s%s%s%s%s%s%s", $1,OFS, out[1],OFS, out[2],OFS, $5,OFS, $6,OFS, $7; for(i=9; i<NF; i++){printf "%s%s", OFS, $i}; if(NF != 8){ printf "%s%s", OFS,$NF }else{printf "%s","\n"}}' > core_vars

LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 core_vars ${STAT} 

