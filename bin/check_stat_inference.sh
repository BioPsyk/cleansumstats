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

#which variables to infer
#Zscore
if [ ${tfB} == "true" ] && [ ${tfSE} == "true" ]; then
  echo -e "Z_fr_B_SE\tfunx_Eff_Err_2_Z(${B},${SE})"
fi
if [ ${tfOR} == "true" ] && [ ${tfSE} == "true" ]; then
  echo -e "Z_fr_OR_SE\tfunx_OR_logORErr_2_Z(${OR},${SE})"
fi
if [ ${tfOR} == "true" ] && [ ${tfP} == "true" ]; then
  echo -e "Z_fr_OR_P\tfunx_OR_and_Pvalue_2_Z(${OR},${P})"
fi


