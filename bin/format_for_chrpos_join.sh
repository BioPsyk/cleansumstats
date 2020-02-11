#!/usr/bin/env bash

FILE_PATH=${1}
MEFL=${2}

function selRightHand(){
  echo "${1#*=}"
}

function selColRow(){
  grep ${1} ${2}
}

colCHR="$(selRightHand "$(selColRow "^colCHR=" ${MEFL})")"
colPOS="$(selRightHand "$(selColRow "^colPOS=" ${MEFL})")"

cat ${FILE_PATH} | sstools-utils ad-hoc-do -k "0|${colCHR}|${colPOS}" -n"0,CHR,BP" | awk -vFS="\t" -vOFS="\t" '{print $2":"$3,$1}' 
