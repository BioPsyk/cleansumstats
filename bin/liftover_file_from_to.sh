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
  if [ ${NR} == "all" ]
  then
    cat ${FILE_PATH} | sstools-utils ad-hoc-do -k "0|${colCHR}|${colPOS}" -n"0,CHR,BP" | awk -vFS="\t" -vOFS="\t" '{print $2":"$3,$1}' 
  else                                                                                                                
    cat ${FILE_PATH} | head -n${NR} | sstools-utils ad-hoc-do -k "0|${colCHR}|${colPOS}" -n"0,CHR,BP" | awk -vFS="\t" -vOFS="\t" '{print $2":"$3,$1}' 
  fi
else                                                                                                                
  if [ ${NR} == "all" ]
  then
    cat ${FILE_PATH} | sstools-utils ad-hoc-do -k "0|${colCHR}|${colPOS}" -n"0,CHR,BP" | awk -vFS="\t" -vOFS="\t" '{print $2":"$3,$1}' | sstools-gb liftover -f - -g ${FROM} -q ${TO} -s 10000 -i "chrpos=1,inx=2" 
  else                                                                                                                
    cat ${FILE_PATH} | head -n${NR} | sstools-utils ad-hoc-do -k "0|${colCHR}|${colPOS}" -n"0,CHR,BP" | awk -vFS="\t" -vOFS="\t" '{print $2":"$3,$1}' | sstools-gb liftover -f - -g ${FROM} -q ${TO} -s 10000 -i "chrpos=1,inx=2" 
  fi
fi

