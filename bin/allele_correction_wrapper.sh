#!/usr/bin/env bash

FILE_PATH_1=${1}
FILE_PATH_2=${2}
MEFL=${3}
OPTION=${4}

function selRightHand(){
  echo "${1#*=}"
}
function selColRow(){
  grep ${1} ${2}
}

#colA1="$(selRightHand "$(selColRow "^colA1=" ${MEFL})")"
#colA1="funx_lowCase_2_upperCase(${colA1})"
colA1=\$(map_to_adhoc_function.sh ${ch_regexp_lexicon} ${MEFL} ${FILE_PATH_1} "effAllele")

if [ "${OPTION}" == "A2missing" ]; then

  cat ${FILE_PATH_1} | sstools-utils ad-hoc-do -k "0|${colA1}" -n"0,A1" | LC_ALL=C join -t "$(printf '\t')" -o 1.1 1.2 2.2 2.3 2.4 2.5 -1 1 -2 1 - ${FILE_PATH_2} | sstools-eallele correction -f - -a

elif [ "${OPTION}" == "A2exists" ]; then

#  colA2="$(selRightHand "$(selColRow "^colA2=" ${MEFL})")"
#  colA2="funx_lowCase_2_upperCase(${colA2})"
   colA2=\$(map_to_adhoc_function.sh ${ch_regexp_lexicon} ${MEFL} ${FILE_PATH_1} "altAllele")
  cat ${FILE_PATH_1} | sstools-utils ad-hoc-do -k "0|${colA1}|${colA2}" -n"0,A1,A2" | LC_ALL=C join -t "$(printf '\t')" -o 1.1 1.2 1.3 2.2 2.3 2.4 2.5 -1 1 -2 1 - ${FILE_PATH_2} | sstools-eallele correction -f -

else

  echo "not a possible option" 

fi


