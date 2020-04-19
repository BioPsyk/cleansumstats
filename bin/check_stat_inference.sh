#!/usr/bin/env bash

#meta file
mefl=${1}

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

#true or false (exists or not)
tfB="$(recode_to_tf $B)"
tfSE="$(recode_to_tf $SE)"
tfZ="$(recode_to_tf $Z)"
tfP="$(recode_to_tf $P)"
tfOR="$(recode_to_tf $OR)"

#which variables to infer
#Zscore
if [ ${tfB} == "true" ] && [ ${tfSE} == "true" ]; then
  echo -e "Z_fr_B_SE\tfunx_Eff_Err_2_Z(${B},${SE})"
fi
if [ ${tfOR} == "true" ] && [ ${tfSE} == "true" ]; then
  echo -e "Z_fr_OR_SE\tfunx_OR_logORErr_2_Z(${OR},${SE})"
fi
if [ ${tfOR} == "true" ] && [ ${tfP} == "true" ]; then
  echo -e "Z_fr_OR_P\tfunx_OR_and_QNORM_2_Z(${OR},QNORM)"
fi

#funx_logOR_logORErr_2_Z(logOddsRatio,logOddsRatioStandardError) 2
#funx_logOR_and_Pvalue_2_Z(logOddsRatio,Pvalue) 2


