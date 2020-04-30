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
B="$(selRightHand "$(selColRow "^col_BETA=" $mefl)")"
SE="$(selRightHand "$(selColRow "^col_SE=" $mefl)")"
Z="$(selRightHand "$(selColRow "^col_Z=" $mefl)")"
P="$(selRightHand "$(selColRow "^col_P=" $mefl)")"
OR="$(selRightHand "$(selColRow "^col_OR=" $mefl)")"
ORL95="$(selRightHand "$(selColRow "^col_ORL95=" $mefl)")"
ORU95="$(selRightHand "$(selColRow "^col_ORU95=" $mefl)")"
N="$(selRightHand "$(selColRow "^col_N=" $mefl)")"
CaseN="$(selRightHand "$(selColRow "^col_CaseN=" $mefl)")"
ControlN="$(selRightHand "$(selColRow "^col_ControlN=" $mefl)")"
AFREQ="$(selRightHand "$(selColRow "^col_AFREQ=" $mefl)")"
INFO="$(selRightHand "$(selColRow "^col_INFO=" $mefl)")"
DIRECTION="$(selRightHand "$(selColRow "^col_Direction=" $mefl)")"


#true or false (exists or not)
tfB="$(recode_to_tf $B)"
tfSE="$(recode_to_tf $SE)"
tfZ="$(recode_to_tf $Z)"
tfP="$(recode_to_tf $P)"
tfOR="$(recode_to_tf $OR)"
tfORL95="$(recode_to_tf $ORL95)"
tfORU95="$(recode_to_tf $ORU95)"
tfN="$(recode_to_tf $N)"
tfCaseN="$(recode_to_tf $CaseN)"
tfControlN="$(recode_to_tf $ControlN)"
tfAFREQ="$(recode_to_tf $AFREQ)"
tfINFO="$(recode_to_tf $INFO)"
tfDIRECTION="$(recode_to_tf $DIRECTION)"


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
  if [ ${tfORL95} == "true" ]; then
    echo -e "${ORL95}"
    echo "ORL95" 1>&2
  fi

  if [ ${tfORU95} == "true" ]; then
    echo -e "${ORU95}"
    echo "ORU95" 1>&2
  fi
  if [ ${tfN} == "true" ]; then
    echo -e "${N}"
    echo "N" 1>&2
  fi
  if [ ${tfCaseN} == "true" ]; then
    echo -e "${CaseN}"
    echo "CaseN" 1>&2
  fi
  if [ ${tfControlN} == "true" ]; then
    echo -e "${ControlN}"
    echo "ControlN" 1>&2
  fi
  if [ ${tfAFREQ} == "true" ]; then
    echo -e "${AFREQ}"
    echo "AFREQ" 1>&2
  fi
  if [ ${tfINFO} == "true" ]; then
    echo -e "${INFO}"
    echo "INFO" 1>&2
  fi
  if [ ${tfDIRECTION} == "true" ]; then
    echo -e "${DIRECTION}"
    echo "Direction" 1>&2
  fi
}

var=$(which_to_select 2> /dev/null | awk '{printf "%s|", $1}' | sed 's/|$//')
nam=$(which_to_select 2>&1 > /dev/null | awk '{printf "%s,", $1}' | sed 's/,$//')

#cat $stdin | sstools-utils ad-hoc-do -f - -k "0|${var}" -n"0,${nam}" 
if [ -s $inferred ]; then
  LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 $inferred $stdin | sstools-utils ad-hoc-do -f - -k "0|${var}" -n"0,${nam}" 
else
  cat $stdin | sstools-utils ad-hoc-do -f - -k "0|${var}" -n"0,${nam}" 
fi

#cat $inferred | sstools-utils ad-hoc-do -f - -k "0|${Z_fr_B_SE}" -n"0,${Z}" 

