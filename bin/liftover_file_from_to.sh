#!/usr/bin/env bash

FILE_PATH=${1}
FROM=${2}
TO=${3}
NR=${4}
MEFL=${5}

function selRightHand(){
  echo "${1#*=}"
}

function selColRow(){
  grep ${1} ${2}
}

colCHR="$(selRightHand "$(selColRow "^colCHR=" ${MEFL})")"
colPOS="$(selRightHand "$(selColRow "^colPOS=" ${MEFL})")"

if [ ${FROM} == "GRCh38" ]
then
  #echo "0|${colCHR}|${colPOS}" 
  #cat ${FILE_PATH} | head -n${NR} 
  #cat ${FILE_PATH} | head -n10 | awk -f /home/people/jesgaa/repos/nf-core-cleansumstats/bin/awk_col_arrange.awk -v mapcols="0|${colCHR}|${colPOS}" -v newcols="0,CHR,BP" 
  #cat ${FILE_PATH} | head -n${NR} | sstools-utils ad-hoc-do -k "0|${colCHR}|${colPOS}" -n"0,CHR,BP" 
  cat ${FILE_PATH} | head -n${NR} | sstools-utils ad-hoc-do -k "0|${colCHR}|${colPOS}" -n"0,CHR,BP" | awk -vFS="\t" -vOFS="\t" '{print $2":"$3,$1}' 
else                                                                                                                
  #cat ${FILE_PATH} | head -n${NR} | sstools-utils ad-hoc-do -k "0|${colCHR}|${colPOS}" -n"0,CHR,BP" 
  cat ${FILE_PATH} | head -n${NR} | sstools-utils ad-hoc-do -k "0|${colCHR}|${colPOS}" -n"0,CHR,BP" | awk -vFS="\t" -vOFS="\t" '{print $2":"$3,$1}' | sstools-gb liftover -f - -g ${FROM} -q ${TO} -s 10000 -i "chrpos=1,inx=2" 
fi

