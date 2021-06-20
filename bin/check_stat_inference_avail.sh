#!/usr/bin/env bash

#meta file
mefl=$1
colf=$2
coln=$3
argn=$4

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

#which args to use
array1=($B $SE $Z $P $OR $ORL95 $ORU95 $N $CaseN $ControlN $EAF2)
array2=($tfB $tfSE $tfZ $tfP $tfOR $tfORL95 $tfORU95 $tfN $tfCaseN $tfControlN $tfEAF2)
array3=("beta" "standarderror" "zscore" "pvalue" "oddsratio" "ORu95" "ORl95" "Nindividuals" "Ncases" "Ncontrols" "allelefreq")

printf "%s" "0" > ${coln}
printf "%s" "0" > ${colf}
printf "%s" "--index 1" > ${argn}

c=1
for i in {0..10}; do
  if [ "${array2[i]}" == "true" ];then
    c=$((c+1))
    printf ",%s" "${array1[i]}" >> ${coln}
    printf "|%s" "${array1[i]}" >> ${colf}
    printf " %s" "--${array3[i]} $c" >> ${argn}
  else
    :
  fi
done

#set newline
printf "\n" >> ${coln}
printf "\n" >> ${colf}
printf "\n" >> ${argn}
