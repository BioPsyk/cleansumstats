#!/usr/bin/env bash

#meta file
mefl=${1}
af_branch=${2}

#helpers
function selRightHand(){
  echo "${1#*: }"
}
function selColRow(){
  grep ${1} ${2}
}

#recode as true or false
function recode_to_tf(){
  if [ "$1" == "" ]; then
    echo false
  else
    echo true
  fi
}

#what is statmethod according to meta data file
STATM="$(selRightHand "$(selColRow "^stats_Model:" $mefl)")"

#what is colname according to meta data file
B="$(selRightHand "$(selColRow "^col_BETA:" $mefl)")"
SE="$(selRightHand "$(selColRow "^col_SE:" $mefl)")"
Z="$(selRightHand "$(selColRow "^col_Z:" $mefl)")"
P="$(selRightHand "$(selColRow "^col_P:" $mefl)")"
OR="$(selRightHand "$(selColRow "^col_OR:" $mefl)")"
N="$(selRightHand "$(selColRow "^col_N:" $mefl)")"
EAF="$(selRightHand "$(selColRow "^col_EAF:" $mefl)")"
OAF="$(selRightHand "$(selColRow "^col_OAF:" $mefl)")"

#true or false (exists or not)
tfB="$(recode_to_tf $B)"
tfSE="$(recode_to_tf $SE)"
tfZ="$(recode_to_tf $Z)"
tfP="$(recode_to_tf $P)"
tfOR="$(recode_to_tf $OR)"
tfN="$(recode_to_tf $P)"
tfEAF="$(recode_to_tf $EAF)"
tfOAF="$(recode_to_tf $OAF)"

#Check if either EAF or OAF is specified in meta, if so, use the new variable with fixed name: EAF
if [ "$af_branch" == "g1kaf_stats_branch" ]; then
    EAF2="AF_1KG_CS"
    tfEAF2="true"
else
  if [ "$tfEAF" == true ] || [ "$tfOAF" == true ]; then
    EAF2="EAF"
    tfEAF2="true"
  else
    EAF2="missing"
    tfEAF2="false"
  fi

fi

#which variables to infer
if [ ${STATM} == "linear" ]; then
  if [ ${tfB} == "true" ] && [ ${tfSE} == "true" ]; then
    echo -e "zscore_from_beta_se"
  fi
  if [ ${tfB} == "true" ] && [ ${tfP} == "true" ]; then
    echo -e "zscore_from_pval_beta"
  fi
  if [ ${tfB} == "true" ] && [ ${tfP} == "true" ] && [ ${tfN} == "true" ]; then
    echo -e "zscore_from_pval_beta_N"
  fi
  if [ ${tfZ} == "true" ] && [ ${tfN} == "true" ]; then
    echo -e "pval_from_zscore_N"
  fi
  if [ ${tfZ} == "true" ]; then
    echo -e "pval_from_zscore"
  fi
  if [ ${tfZ} == "true" ] && [ ${tfSE} == "true" ]; then
    echo -e "beta_from_zscore_se"
  fi
  if [ ${tfZ} == "true" ] && [ ${tfN} == "true" ] && [ ${tfEAF2} == "true" ]; then
    echo -e "beta_from_zscore_N_af"
  fi
  if [ ${tfZ} == "true" ] && [ ${tfB} == "true" ]; then
    echo -e "se_from_zscore_beta"
  fi
  if [ ${tfZ} == "true" ] && [ ${tfN} == "true" ] && [ ${tfEAF2} == "true" ]; then
    echo -e "se_from_zscore_N_af"
  fi
  if [ ${tfZ} == "true" ] && [ ${tfB} == "true" ] && [ ${tfEAF2} == "true" ]; then
    echo -e "N_from_zscore_beta_af"
  fi
fi
