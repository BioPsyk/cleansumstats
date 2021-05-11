#!/usr/bin/env bash

#meta file
mefl=${1}

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

#what is colname according to meta data file
TraitType="$(selRightHand "$(selColRow "^stats_TraitType:" $mefl)")"
TotalN="$(selRightHand "$(selColRow "^stats_TotalN:" $mefl)")"
CaseN="$(selRightHand "$(selColRow "^stats_CaseN:" $mefl)")"
ControlN="$(selRightHand "$(selColRow "^stats_ControlN:" $mefl)")"


#true or false (exists or not)
tfTraitType="$(recode_to_tf $TraitType)"
tfTotalN="$(recode_to_tf $TotalN)"
tfCaseN="$(recode_to_tf $CaseN)"
tfControlN="$(recode_to_tf $ControlN)"

#which variables to infer
if [ ${tfTraitType} == "true" ] && [ ${tfTotalN} == "true" ]
then
  if [ ${TraitType} == "quantitative" ]
  then
    #effective N is total N
    stats_EffectiveN=${TotalN}
  elif [ ${TraitType} == "ordinal" ]
  then
    #effective N is total N
    stats_EffectiveN=${TotalN}
  elif [ ${TraitType} == "case-control" ]
  then
    if [ ${tfTraitType} == "true" ] && [ ${tfTotalN} == "true" ]
    then
      #use awk to calculate effective N from case N and control N
      stats_EffectiveN="$(echo -e "${CaseN}" | awk -vctrln=${ControlN} '{ret=4/((1/$1)+(1/ctrln)); print ret}')"
    else
      stats_EffectiveN=missing
    fi
  else
    stats_EffectiveN=missing
  fi
fi

#return complete meat file field
echo "stats_EffectiveN: ${stats_EffectiveN}"
