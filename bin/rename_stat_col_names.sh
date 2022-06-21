#!/usr/bin/env bash

#meta file
stats=${1}
B=${2}
SE=${3}
Z=${4}
P=${5}
OR=${6}
ORL95=${7}
ORU95=${8}
N=${9}
CaseN=${10}
ControlN=${11}
INFO=${12}
DIRECTION=${13}
StudyN=${14}
EAF=${15}
OAF=${16}

#recode as true or false
function recode_to_tf(){
  if [ "$1" == "missing" ]; then
    echo false
  else
    echo true
  fi
}

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
tfINFO="$(recode_to_tf $INFO)"
tfDIRECTION="$(recode_to_tf $DIRECTION)"
tfStudyN="$(recode_to_tf $StudyN)"
tfEAF="$(recode_to_tf $EAF)"
tfOAF="$(recode_to_tf $OAF)"

#Special treatment to EAF as it has been forced to be EAF already
if [ "$tfEAF" == true ] || [ "$tfOAF" == true ]; then
  EAF2="EAF"
  tfEAF2="true"
else
  EAF2="missing"
  tfEAF2="false"
fi

#This is the order the columns will show up
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
  if [ ${tfEAF2} == "true" ]; then
    echo -e "${EAF2}"
    echo "EAF" 1>&2
  fi
  if [ ${tfINFO} == "true" ]; then
    echo -e "${INFO}"
    echo "INFO" 1>&2
  fi
  if [ ${tfDIRECTION} == "true" ]; then
    echo -e "${DIRECTION}"
    echo "DIRECTION" 1>&2
  fi
  if [ ${tfStudyN} == "true" ]; then
    echo -e "${StudyN}"
    echo "StudyN" 1>&2
  fi
}

var=$(which_to_select 2> /dev/null | awk '{printf "%s|", $1}' | sed 's/|$//')
nam=$(which_to_select "/dev/null" 2>&1 > /dev/null | awk '{printf "%s,", $1}' | sed 's/,$//')

cat $stats | sstools-utils ad-hoc-do -f - -k "0|${var}" -n"0,${nam}"

