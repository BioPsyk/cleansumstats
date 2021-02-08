#!/usr/bin/env bash

#meta file
mefl=${1}
stdin=${2}
inferred=${3}

#helpers
function selRightHand(){
  echo "${1#*: }"
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
  head -n1 $infs | awk '{print $0" "}'1 | grep -q "[[:space:]]$var[[:space:]]"
}

#what is colname according to meta data file
B="$(selRightHand "$(selColRow "^col_BETA:" $mefl)")"
SE="$(selRightHand "$(selColRow "^col_SE:" $mefl)")"
Z="$(selRightHand "$(selColRow "^col_Z:" $mefl)")"
P="$(selRightHand "$(selColRow "^col_P:" $mefl)")"
OR="$(selRightHand "$(selColRow "^col_OR:" $mefl)")"
ORL95="$(selRightHand "$(selColRow "^col_ORL95:" $mefl)")"
ORU95="$(selRightHand "$(selColRow "^col_ORU95:" $mefl)")"
N="$(selRightHand "$(selColRow "^col_N:" $mefl)")"
CaseN="$(selRightHand "$(selColRow "^col_CaseN:" $mefl)")"
ControlN="$(selRightHand "$(selColRow "^col_ControlN:" $mefl)")"
EAF="$(selRightHand "$(selColRow "^col_EAF:" $mefl)")"
OAF="$(selRightHand "$(selColRow "^col_OAF:" $mefl)")"
INFO="$(selRightHand "$(selColRow "^col_INFO:" $mefl)")"
DIRECTION="$(selRightHand "$(selColRow "^col_Direction:" $mefl)")"


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
tfEAF="$(recode_to_tf $EAF)"
tfOAF="$(recode_to_tf $OAF)"
tfINFO="$(recode_to_tf $INFO)"
tfDIRECTION="$(recode_to_tf $DIRECTION)"

if [ "$tfEAF" == true ] || [ "$tfOAF" == true ]; then
  EAF2="EAF"
  tfEAF2="true"
else
  EAF2="missing"
  tfEAF2="false"
fi


#which variables to filter
function which_to_select(){
  if [ ${tfB} == "true" ]; then
    echo -e "${B}"
    echo "B" 1>&2
  else
    if specfunx_exists "beta_from_zscore_se" ${inferred}; then
      echo "beta_from_zscore_se"
      echo "B" 1>&2
    elif specfunx_exists "beta_from_zscore_N_af" ${inferred}; then
      echo "beta_from_zscore_N_af"
      echo "B" 1>&2
    elif specfunx_exists "beta_from_zscore_se_1KG" ${inferred}; then
      echo "beta_from_zscore_se_1KG"
      echo "B" 1>&2
    elif specfunx_exists "beta_from_zscore_N_af_1KG" ${inferred}; then
      echo "beta_from_zscore_N_af_1KG"
      echo "B" 1>&2
    else
      :
    fi
  fi
  if [ ${tfSE} == "true" ]; then
    echo -e "${SE}"
    echo "SE" 1>&2
  else
    if specfunx_exists "se_from_zscore_beta" ${inferred}; then
      echo "se_from_zscore_beta"
      echo "SE" 1>&2
    elif specfunx_exists "se_from_zscore_N_af" ${inferred}; then
      echo "se_from_zscore_N_af"
      echo "SE" 1>&2
    elif specfunx_exists "se_from_zscore_beta_1KG" ${inferred}; then
      echo "se_from_zscore_beta_1KG"
      echo "SE" 1>&2
    elif specfunx_exists "se_from_zscore_N_af_1KG" ${inferred}; then
      echo "se_from_zscore_N_af_1KG"
      echo "SE" 1>&2
    else
      :
    fi
  fi
  if [ ${tfZ} == "true" ]; then
    echo -e "${Z}"
    echo "Z" 1>&2
  else
    if specfunx_exists "zscore_from_beta_se" ${inferred}; then
      echo "zscore_from_beta_se"
      echo "Z" 1>&2
    elif specfunx_exists "zscore_from_pval_beta" ${inferred}; then
      echo "zscore_from_pval_beta"
      echo "Z" 1>&2
    elif specfunx_exists "zscore_from_pval_beta_N" ${inferred}; then
      echo "zscore_from_pval_beta_N"
      echo "Z" 1>&2
    elif specfunx_exists "zscore_from_beta_se_1KG" ${inferred}; then
      echo "zscore_from_beta_se_1KG"
      echo "Z" 1>&2
    elif specfunx_exists "zscore_from_pval_beta_1KG" ${inferred}; then
      echo "zscore_from_pval_beta_1KG"
      echo "Z" 1>&2
    elif specfunx_exists "zscore_from_pval_beta_N_1KG" ${inferred}; then
      echo "zscore_from_pval_beta_N_1KG"
      echo "Z" 1>&2
    else
      :
    fi
  fi
  if [ ${tfP} == "true" ]; then
    echo -e "${P}"
    echo "P" 1>&2
  else
    if specfunx_exists "pval_from_zscore_N" ${inferred}; then
      echo "pval_from_zscore_N"
      echo "P" 1>&2
    elif specfunx_exists "pval_from_zscore" ${inferred}; then
      echo "pval_from_zscore"
      echo "P" 1>&2
    elif specfunx_exists "pval_from_zscore_N_1KG" ${inferred}; then
      echo "pval_from_zscore_N_1KG"
      echo "P" 1>&2
    elif specfunx_exists "pval_from_zscore_1KG" ${inferred}; then
      echo "pval_from_zscore_1KG"
      echo "P" 1>&2
    else
      :
    fi
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
    if specfunx_exists "N_from_zscore_beta_af" ${inferred}; then
      echo "N_from_zscore_beta_af"
      echo "N" 1>&2
    elif specfunx_exists "N_from_zscore_beta_af_1KG" ${inferred}; then
      echo "N_from_zscore_beta_af_1KG"
      echo "N" 1>&2
    else
      :
    fi
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
  if specfunx_exists "AF_1KG_CS" ${stdin}; then
    echo -e "AF_1KG_CS"
    echo "EAF_1KG" 1>&2
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
