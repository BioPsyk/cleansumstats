#!/usr/bin/env bash

ACOR=${1}
STAT=${2}

function selRightHand(){
  echo "${1#*=}"
}
function selColRow(){
  grep ${1} ${2}
}

function stat_exists(){
  var=$1
  infs=$2
  #could be good to rewrite this funtion to split and then process each row
  #right now we might grep the wrong thing in case another colname starts with "N"
  head -n1 $infs | grep -q "[[:space:]]$var"
}

function which_to_mod(){
    if stat_exists "B" ${STAT}; then
      echo "B"
      echo "B" 1>&2
    fi
   #needs special care for allele flipping
   # if stat_exists "OR" ${STAT}; then
   #   echo "OR"
   #   echo "OR" 1>&2
   # fi
    if stat_exists "Z" ${STAT}; then
      echo "Z"
      echo "Z" 1>&2
    fi
}

function which_to_keep(){
    if stat_exists "P" ${STAT}; then
      echo "P"
      echo "P" 1>&2
    fi
    if stat_exists "SE" ${STAT}; then
      echo "SE"
      echo "SE" 1>&2
    fi
    if stat_exists "ORL95" ${STAT}; then
      echo "ORL95"
      echo "ORL95" 1>&2
    fi
    if stat_exists "ORU95" ${STAT}; then
      echo "ORU95"
      echo "ORU95" 1>&2
    fi
    if stat_exists "N" ${STAT}; then
      echo "N"
      echo "N" 1>&2
    fi
    if stat_exists "CaseN" ${STAT}; then
      echo "CaseN"
      echo "CaseN" 1>&2
    fi
    if stat_exists "ControlN" ${STAT}; then
      echo "ControlN"
      echo "ControlN" 1>&2
    fi
   #needs special care for allele flipping
   # if stat_exists "AFREQ" ${STAT}; then
   #   echo "AFREQ"
   #   echo "AFREQ" 1>&2
   # fi
    if stat_exists "INFO" ${STAT}; then
      echo "INFO"
      echo "INFO" 1>&2
    fi
    if stat_exists "Direction" ${STAT}; then
      echo "Direction"
      echo "Direction" 1>&2
    fi
}

var_m=$(which_to_mod 2> /dev/null | awk '{printf "%s|", $1}' | sed 's/|$//')
nam_m=$(which_to_mod 2>&1 > /dev/null | awk '{printf "%s,", $1}' | sed 's/,$//')
var_k=$(which_to_keep 2> /dev/null | awk '{printf "%s|", $1}' | sed 's/|$//')
nam_k=$(which_to_keep 2>&1 > /dev/null | awk '{printf "%s,", $1}' | sed 's/,$//')

if [ -z "$var_m" ]; then
# -z returns true if variable is unset
  cat $ACOR | sed 's/[[:space:]]*$//' | awk -vFS="\t" -vOFS="\t" 'NR==1{printf "%s%s%s%s%s%s%s%s%s%s%s", $1,OFS, "CHR",OFS, "POS",OFS, $5,OFS, $6,OFS, $7; for(i=9; i<NF; i++){printf "%s%s", OFS, $i}; if(NF != 8){ printf "%s%s", OFS,$NF }else{printf "%s","\n"}} NR>1{split($4,out,":"); for(i=9; i<=NF; i++){$i=$i*$8}; printf "%s%s%s%s%s%s%s%s%s%s%s", $1,OFS, out[1],OFS, out[2],OFS, $5,OFS, $6,OFS, $7; for(i=9; i<NF; i++){printf "%s%s", OFS, $i}; if(NF != 8){ printf "%s%s", OFS,$NF }else{printf "%s","\n"}}' | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 - <(sstools-utils ad-hoc-do -f $STAT -k "0|${var_k}" -n"0,${nam_k}" )
else
# do this if there are variables in $var_m
  LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 $ACOR <(sstools-utils ad-hoc-do -f $STAT -k "0|${var_m}" -n"0,${nam_m}" ) | sed 's/[[:space:]]*$//' | awk -vFS="\t" -vOFS="\t" 'NR==1{printf "%s%s%s%s%s%s%s%s%s%s%s%s", $1,OFS, "CHR",OFS, "POS",OFS, $5,OFS, $6,OFS, $7,OFS; for(i=9; i<NF; i++){printf "%s%s", $i, OFS}; print $NF} NR>1{split($4,out,":"); for(i=9; i<=NF; i++){$i=$i*$8}; printf "%s%s%s%s%s%s%s%s%s%s%s%s", $1,OFS, out[1],OFS, out[2],OFS, $5,OFS, $6,OFS, $7,OFS; for(i=9; i<NF; i++){printf "%s%s", $i, OFS}; print $NF}' | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 - <(sstools-utils ad-hoc-do -f $STAT -k "0|${var_k}" -n"0,${nam_k}" )

fi

