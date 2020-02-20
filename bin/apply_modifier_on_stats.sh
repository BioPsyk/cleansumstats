#!/usr/bin/env bash

FILE_PATH=${1}
FILE_PATH2=${2}
MEFL=${3}
function selRightHand(){
  echo "${1#*=}"
}
function selColRow(){
  grep ${1} ${2}
}

colZ="$(selRightHand "$(selColRow "^colZ=" ${MEFL})")"

sstools-utils ad-hoc-do -f ${FILE_PATH} -k "0|${colZ}" -n"0,zscore" | LC_ALL=C join -t "$(printf '\t')" -o 1.1 1.2 2.8 -1 1 -2 1 - <( cat ${FILE_PATH2}) | awk -vFS="\t" -vOFS="\t" '{$2=$2*$3}'1 | awk -vFS="\t" -vOFS="\t" '{print $1, $2}' 


