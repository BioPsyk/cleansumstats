#!/usr/bin/env bash

ACOR=${1}
STAT=${2}

function selRightHand(){
  echo "${1#*: }"
}
function selColRow(){
  grep ${1} ${2}
}

function stat_exists(){
  var=$1
  infs=$2
  #could be good to rewrite this funtion to split and then process each row (but works for now)
  head -n1 $infs | awk '{print $0" "}'1 | grep -q "[[:space:]]$var[[:space:]]"
}

function which_to_mod(){
    if stat_exists "B" ${STAT}; then
      echo "B"
      echo "B" 1>&2
    fi
    if stat_exists "Z" ${STAT}; then
      echo "Z"
      echo "Z" 1>&2
    fi
}

function which_to_mod2(){
    if stat_exists "EAF" ${STAT}; then
      echo "EAF"
      echo "EAF" 1>&2
    fi
    if stat_exists "EAF_1KG" ${STAT}; then
      echo "EAF_1KG"
      echo "EAF_1KG" 1>&2
    fi
}

function which_to_mod3(){
    if stat_exists "OR" ${STAT}; then
      echo "OR"
      echo "OR" 1>&2
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
    if stat_exists "INFO" ${STAT}; then
      echo "INFO"
      echo "INFO" 1>&2
    fi
    if stat_exists "Direction" ${STAT}; then
      echo "Direction"
      echo "Direction" 1>&2
    fi
    if stat_exists "StudyN" ${STAT}; then
      echo "StudyN"
      echo "StudyN" 1>&2
    fi
}

unset var_m var_m2 var_m3

var_m=$(which_to_mod 2> /dev/null | awk '{printf "%s|", $1}' | sed 's/|$//')
nam_m=$(which_to_mod 2>&1 > /dev/null | awk '{printf "%s,", $1}' | sed 's/,$//')
var_m2=$(which_to_mod2 2> /dev/null | awk '{printf "%s|", $1}' | sed 's/|$//')
nam_m2=$(which_to_mod2 2>&1 > /dev/null | awk '{printf "%s,", $1}' | sed 's/,$//')
var_m3=$(which_to_mod3 2> /dev/null | awk '{printf "%s|", $1}' | sed 's/|$//')
nam_m3=$(which_to_mod3 2>&1 > /dev/null | awk '{printf "%s,", $1}' | sed 's/,$//')

var_k=$(which_to_keep 2> /dev/null | awk '{printf "%s|", $1}' | sed 's/|$//')
nam_k=$(which_to_keep 2>&1 > /dev/null | awk '{printf "%s,", $1}' | sed 's/,$//')

#selected stats variables that are NOT going to be modified
sstools-utils ad-hoc-do -f $STAT -k "0|${var_k}" -n"0,${nam_k}" > sel_stats_k

#Prepare from ACOR the data not modified
cat $ACOR \
  | sed 's/[[:space:]]*$//' \
  | awk -vFS="\t" -vOFS="\t" 'NR==1{printf "%s%s%s%s%s%s%s%s%s%s%s", $1,OFS, "CHR",OFS, "POS",OFS, $5,OFS, $6,OFS, $7; for(i=9; i<NF; i++){printf "%s%s", OFS, $i}; if(NF != 8){ printf "%s%s", OFS,$NF }else{printf "%s","\n"}} NR>1{split($4,out,":"); for(i=9; i<=NF; i++){$i=$i*$8}; printf "%s%s%s%s%s%s%s%s%s%s%s", $1,OFS, out[1],OFS, out[2],OFS, $5,OFS, $6,OFS, $7; for(i=9; i<NF; i++){printf "%s%s", OFS, $i}; if(NF != 8){ printf "%s%s", OFS,$NF }else{printf "%s","\n"}}' > core_vars


# -z returns true if variable is unset
if [ -z "$var_m" ] && [ -z "$var_m2" ] && [ -z "$var_m3" ]
then
  #echo "hej"
  LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 core_vars sel_stats_k

else
  #selected stats variables that are going to be modified
  awk -vFS="\t" -vOFS="\t" '{print $1,$8}' $ACOR > modifier

  #1*var
  if [ -n "$var_m" ]
  then
    sstools-utils ad-hoc-do -f $STAT -k "0|${var_m}" -n"0,${nam_m}" | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 modifier - | awk -vFS="\t" -vOFS="\t" 'NR==1{printf "%s", $1; for(i=3; i<=NF; i++){printf "%s%s", OFS, $i}; printf "%s", RS }; NR>1{printf "%s", $1; for(i=3; i<=NF; i++){printf "%s%s", OFS, $2*$i}; printf "%s", RS}' > sel_stats_m
  else
    :
  fi
  #1-var
  if [ -n "$var_m2" ] ; then
    sstools-utils ad-hoc-do -f $STAT -k "0|${var_m2}" -n"0,${nam_m2}" | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 modifier - | awk -vFS="\t" -vOFS="\t" 'NR==1{printf "%s", $1; for(i=3; i<=NF; i++){printf "%s%s", OFS, $i}; printf "%s", RS }; NR>1{printf "%s", $1; for(i=3; i<=NF; i++){if($2=="1" || $i=="NA"){printf "%s%s", OFS, $i}else{printf "%s%s", OFS, 1-$i}}; printf "%s", RS}' > sel_stats_m2
  else
    :
  fi
  #1/var
  if [ -n "$var_m3" ] ; then
    sstools-utils ad-hoc-do -f $STAT -k "0|${var_m3}" -n"0,${nam_m3}" | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 modifier - | awk -vFS="\t" -vOFS="\t" 'NR==1{printf "%s", $1; for(i=3; i<=NF; i++){printf "%s%s", OFS, $i}; printf "%s", RS }; NR>1{printf "%s", $1; for(i=3; i<=NF; i++){if($2=="1"){printf "%s%s", OFS, $i}else{printf "%s%s", OFS, 1/$i}}; printf "%s", RS}' > sel_stats_m3
  else
    :
  fi

  #connect it now in some clever way depending on if we have both or only one of the modified variants
  if [ -n "$var_m" ] && [ -n "$var_m2" ] && [ -n "$var_m3" ] ; then
    LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 core_vars sel_stats_k | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 - sel_stats_m | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 - sel_stats_m2 | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 - sel_stats_m3
  elif [ -n "$var_m" ] && [ -n "$var_m3" ] ; then
    LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 core_vars sel_stats_k | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 - sel_stats_m | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 - sel_stats_m3
  elif [ -n "$var_m2" ] && [ -n "$var_m3" ] ; then
    LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 core_vars sel_stats_k | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 - sel_stats_m2 | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 - sel_stats_m3
  elif [ -n "$var_m" ] && [ -n "$var_m2" ] ; then
    LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 core_vars sel_stats_k | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 - sel_stats_m | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 - sel_stats_m2
  elif [ -n "$var_m" ] ; then
    LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 core_vars sel_stats_k | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 - sel_stats_m
  elif [ -n "$var_m2" ] ; then
    LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 core_vars sel_stats_k | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 - sel_stats_m2
  else
    LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 core_vars sel_stats_k | LC_ALL=C join -t "$(printf '\t')" -1 1 -2 1 - sel_stats_m3
  fi
fi

