#!/usr/bin/env bash

MEFL=${1}

function selRightHand(){
  echo "${1#*: }"
}

function selColRow(){
  grep ${1} ${2}
}

colA2="$(selRightHand "$(selColRow "^col_OtherAllele:" ${MEFL})")"

if [ ${colA2} == "missing" ]
then
  echo false
else
  echo true
fi
