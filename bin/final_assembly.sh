#!/usr/bin/env bash

FILE_PATH=${1}
FILE_PATH2=${2}
FILE_PATH3=${3}
#MEFL=${4}
#function selRightHand(){
#  echo "${$(grep "^colP=" ${MEFL})#*=}"
#}
#function selColRow(){
#  grep ${1} ${2}
#}
#
#colP="$(selRightHand "$(selColRow "^colP=" ${MEFL})")"
#colP="$(selRightHand "$(selColRow "^colP=" ${MEFL})")"

cat ${FILE_PATH} | awk -vFS="\t" -vOFS="\t" '{split($4,out,":")}{print $1, out[1], out[2], $6}' | LC_ALL=C join -t "$(printf '\t')" -o 1.1 1.2 1.3 1.4 2.2 -1 1 -2 1 - <( cat ${FILE_PATH2}) | cat <(printf "%s\t%s\t%s\t%s\t%s\n" "0" "CHR" "BP" "A1" "Zscore") - | LC_ALL=C join -t "$(printf '\t')" -o 1.1 1.2 1.3 1.4 1.5 2.2 -1 1 -2 1 - $FILE_PATH3 

