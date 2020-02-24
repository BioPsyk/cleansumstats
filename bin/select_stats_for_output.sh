#!/usr/bin/env bash

#meta file
mefl=${1}
stdin=${2}
inferred=${3}

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

#recode as true or false
function specfunx_exists(){
  var=$1
  infs=$2
  head -n1 $infs | grep -q "$var"
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
function which_to_select(){
  if [ ${tfB} == "true" ]; then
    echo -e "${B}"
    echo "B" 1>&2
  fi

  if [ ${tfSE} == "true" ]; then
    echo -e "${SE}"
    echo "SE" 1>&2
  fi

  if [ ${tfZ} == "true" ]; then
    echo -e "${Z}"
    echo "Z" 1>&2
  else
    if specfunx_exists "Z_fr_B_SE" ${inferred}; then
      echo "Z_fr_B_SE"
      echo "Z" 1>&2
    elif specfunx_exists "Z_fr_OR_SE" ${inferred}; then
      echo "Z_fr_OR_SE"
      echo "Z" 1>&2
    elif specfunx_exists "Z_fr_OR_P" ${inferred}; then
      echo "Z_fr_OR_P"
      echo "Z" 1>&2
    else
      :
    fi
  fi

  if [ ${tfP} == "true" ]; then
    echo -e "${P}"
    echo "P" 1>&2
  fi

  if [ ${tfOR} == "true" ]; then
    echo -e "${OR}"
    echo "OR" 1>&2
  fi
}

var=$(which_to_select 2> /dev/null | awk '{printf "%s|", $1}' | sed 's/|$//')
nam=$(which_to_select 2>&1 > /dev/null | awk '{printf "%s,", $1}' | sed 's/,$//')

#cat $stdin | sstools-utils ad-hoc-do -f - -k "0|${var}" -n"0,${nam}" 
LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 $inferred $stdin | sstools-utils ad-hoc-do -f - -k "0|${var}" -n"0,${nam}" 

#cat $inferred | sstools-utils ad-hoc-do -f - -k "0|${Z_fr_B_SE}" -n"0,${Z}" 

