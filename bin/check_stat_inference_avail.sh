#!/usr/bin/env bash

#meta file
mefl=$1
colf=$2
coln=$3
argn=$4

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
N="$(selRightHand "$(selColRow "^col_N=" $mefl)")"
AF="$(selRightHand "$(selColRow "^col_AFREQ=" $mefl)")"

#true or false (exists or not)
tfB="$(recode_to_tf $B)"
tfSE="$(recode_to_tf $SE)"
tfZ="$(recode_to_tf $Z)"
tfP="$(recode_to_tf $P)"
tfOR="$(recode_to_tf $OR)"
tfN="$(recode_to_tf $N)"
tfAF="$(recode_to_tf $AF)"

#which args to use
array1=($B $SE $Z $P $OR $N $AF)
array2=($tfB $tfSE $tfZ $tfP $tfOR $tfN $tfAF)
array3=("beta" "standarderror" "zscore" "pvalue" "oddsratio" "Nindividuals" "allelefreq")

printf "%s" "0" > ${coln}
printf "%s" "0" > ${colf}
printf "%s" "--index 1" > ${argn}

c=1
for i in {0..6}; do
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


