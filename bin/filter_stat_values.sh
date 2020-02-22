#!/usr/bin/env bash

#meta file
mefl=${1}
stdin=${2}

#helpers
function selRightHand(){
  echo "${1#*=}"
}
function selColRow(){
  grep ${1} ${2}
}

#recode as true or false
function recode_to_tf(){
  if [ $1 == "missing" ]; then
  echo false
  else
  echo true
  fi
}

#what is colname according to meta data file
B="$(selRightHand "$(selColRow "^colBETA=" $mefl)")"
SE="$(selRightHand "$(selColRow "^colSE=" $mefl)")"
Z="$(selRightHand "$(selColRow "^colZ=" $mefl)")"
P="$(selRightHand "$(selColRow "^colP=" $mefl)")"
OR="$(selRightHand "$(selColRow "^colOR=" $mefl)")"

#true or false (exists or not)
tfB="$(recode_to_tf $B)"
tfSE="$(recode_to_tf $SE)"
tfZ="$(recode_to_tf $Z)"
tfP="$(recode_to_tf $P)"
tfOR="$(recode_to_tf $OR)"

#which variables to filter
function which_to_filter(){
  if [ ${tfB} == "true" ]; then
    echo -e "${B}"
  fi
  if [ ${tfSE} == "true" ]; then
    echo -e "${SE}"
  fi
  if [ ${tfZ} == "true" ]; then
    echo -e "${Z}"
  fi
  if [ ${tfP} == "true" ]; then
    echo -e "${P}"
  fi
  if [ ${tfOR} == "true" ]; then
    echo -e "${OR}"
  fi
}

var=$(which_to_filter | awk '{printf "%s|", $1}' | sed 's/|$//')
nam=$(which_to_filter | awk '{printf "%s,", $1}' | sed 's/,$//')

#cat $stdin | sstools-utils ad-hoc-do -f - -k "0|${var}" -n"0,${nam}" 
sstools-utils ad-hoc-do -f $stdin -k "0|${var}" -n"0,${nam}" | filter_stat_values_awk.sh 2>st_error

#

