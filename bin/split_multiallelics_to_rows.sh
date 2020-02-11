#!/usr/bin/env bash

FILE_PATH=${1}

cat ${FILE_PATH} |  awk -vFS="\t" -vOFS="\t" '$5 ~ /,/{split($5,out,","); for(k=1; k <= length(out); k++){print $1,$2,$3,$4,out[k]}} $5 !~ /,/{print $0}'




