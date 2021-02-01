#!/usr/bin/env bash

# STRATEGY
#IF SNP, then
#
#  split in two sets, one with rsids and one without
#
#  try chrpos mapping (not the ones with rsid)
#
#  do rsid mapping on the rs-ids
#
#  merge the two sets
#
#
#IF chrpos (not missing) points to column different from SNP, then
#
#  do the chrpos mapping like before
#
#  merge with SNP (if SNP not missing) (chrpos mapping will be prioritized)
#
#
#
##Initial check done in this script
#SNPexists
#CHRPOSexists
#pointsToDifferent


MEFL=${1}

function selRightHand(){
  echo "${1#*: }"
}

function selColRow(){
  grep ${1} ${2}
}

colCHR="$(selRightHand "$(selColRow "^col_CHR:" ${MEFL})")"
colPOS="$(selRightHand "$(selColRow "^col_POS:" ${MEFL})")"
colSNP="$(selRightHand "$(selColRow "^col_SNP:" ${MEFL})")"


pointsToDifferent="true"
if [ "${colCHR}" == "${colSNP}" ] ||  [ "${colPOS}" == "${colSNP}" ]
then
  pointsToDifferent="false"
fi

CHRPOSexists="true"
if [ ${colCHR} == "missing" ] ||  [ ${colPOS} == "missing" ]
then
  CHRPOSexists="false"
fi

SNPexists="true"
if [ ${colSNP} == "missing" ]
then
  SNPexists="false"
fi

#return
echo "pointsToDifferent=${pointsToDifferent}"
echo "CHRPOSexists=${CHRPOSexists}"
echo "SNPexists=${SNPexists}"
