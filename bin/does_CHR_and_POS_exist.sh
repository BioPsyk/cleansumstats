#!/usr/bin/env bash

MEFL=${1}

function selRightHand(){
  echo "${1#*=}"
}

function selColRow(){
  grep ${1} ${2}
}

colCHR="$(selRightHand "$(selColRow "^col_CHR=" ${MEFL})")"
colPOS="$(selRightHand "$(selColRow "^col_POS=" ${MEFL})")"

if [ ${colCHR} == "missing" ] ||  [ ${colPOS} == "missing" ]
then
  echo false
else
  echo true
fi

