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
  if [ ${tfORL95} == "true" ]; then
    echo -e "${ORL95}"
  fi
  if [ ${tfORU95} == "true" ]; then
    echo -e "${ORU95}"
  fi
  if [ ${tfN} == "true" ]; then
    echo -e "${N}"
  fi
  if [ ${tfCaseN} == "true" ]; then
    echo -e "${CaseN}"
  fi
  if [ ${tfControlN} == "true" ]; then
    echo -e "${ControlN}"
  fi
  if [ ${tfAFREQ} == "true" ]; then
    echo -e "${AFREQ}"
  fi
  if [ ${tfINFO} == "true" ]; then
    echo -e "${INFO}"
  fi
}

var=$(which_to_filter | awk '{printf "%s|", $1}' | sed 's/|$//')
nam=$(which_to_filter | awk '{printf "%s,", $1}' | sed 's/,$//')

#cat $stdin | sstools-utils ad-hoc-do -f - -k "0|${var}" -n"0,${nam}" 

#check position for each variable present.
#right now only make a note where SE is present, which is the indicor for which column to do zero value filtering on
i=1
SE_which_col=-1
if [ ${tfB} == "true" ]; then
  ((i++))
fi
if [ ${tfSE} == "true" ]; then
  ((i++))
  SE_which_col=$i
fi
if [ ${tfZ} == "true" ]; then
  ((i++))
fi
if [ ${tfP} == "true" ]; then
  ((i++))
fi
if [ ${tfOR} == "true" ]; then
  ((i++))
fi
if [ ${tfORL95} == "true" ]; then
  ((i++))
fi
if [ ${tfORU95} == "true" ]; then
  ((i++))
fi
if [ ${tfN} == "true" ]; then
  ((i++))
fi
if [ ${tfCaseN} == "true" ]; then
  ((i++))
fi
if [ ${tfControlN} == "true" ]; then
  ((i++))
fi
if [ ${tfAFREQ} == "true" ]; then
  ((i++))
fi
if [ ${tfINFO} == "true" ]; then
  ((i++))
fi

sstools-utils ad-hoc-do -f $stdin -k "0|${var}" -n"0,${nam}" | filter_stat_values_awk.sh -vzeroSE="${SE_which_col}"
#sstools-utils ad-hoc-do -f $stdin -k "0|${var}" -n"0,${nam}" | filter_stat_values_awk.sh

#
