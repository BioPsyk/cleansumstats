#!/usr/bin/env bash


#cat <(head -n1 ${1}) <(cat ${2})

header=($(cat $2 | head -n1 | head -c -2))

#meta file
mefl=${1}

#reporter variable
noError=true

# Does all important tags exist in the metadatafile
colNeeded1=(
colCHR
colPOS
colSNP
colA1
colA2
colBETA
colSE
colOR
colORL95
colORU95
colZ
colP
colN
colAFREQ
colINFO
colCHRtype
colPOStype
colSNPtype
colA1type
colA2type
)
#A set without the types
colNeeded2=(
colCHR
colPOS
colSNP
colA1
colA2
colBETA
colSE
colOR
colORL95
colORU95
colZ
colP
colN
colAFREQ
colINFO
)
#a set with only the types
typeToCheck=(
  colCHRtype
  colPOStype
  colSNPtype
  colA1type
  colA2type
)

function variableMissing(){
  if grep -Pq "${1}" ${2}
  then
      echo false
  else
      echo true
  fi
}

#check that all required paramter names are present in metadata file
for var in ${colNeeded1[@]}; do
  #echo ${var}
  if [ $(variableMissing "^${var}=" ${mefl}) == "true" ]
  then
    echo >&2 "variable missing: ${var}="; 
    noError=false
  else
    :
  fi
done

#examples of pattern types
#chr1:1324324
#1:3434324
#1_34235432_A_T
allowedType=(
  'default$'
  '\d{1,2}:\d+$'
  '\d{1,2}:\d+:\w+$'
  '\d{1,2}:\d+:\w+:\w+$'
  '[c|C][h|H][r|R]\d{1,2}:\d+$'
  '[c|C][h|H][r|R]\d{1,2}:\d+:\w+$'
  '[c|C][h|H][r|R]\d{1,2}:\d+:\w:\w+$'
  '\d{1,2}_\d+$'
  '\d{1,2}_\d+_\w+$'
  '\d{1,2}_\d+_\w_\w+$'
  '[c|C][h|H][r|R]\d{1,2}_\d+$'
  '[c|C][h|H][r|R]\d{1,2}_\d+_\w+$'
  '[c|C][h|H][r|R]\d{1,2}_\d+_\w+_\w+$'
)

function selRightHand(){
  echo "${1#*=}"
}

function selColRow(){
  grep ${1} ${2}
}

function colTypeNotAllowed(){
  if echo ${2} | grep -Pq "${1}"
  then
      echo true
  else
      echo false
  fi
}

#Check all types if the right hand side follows the allowed patterns
for ttc in ${typeToCheck[@]}; do
  #echo ${ttc}
  right="$(selRightHand "$(selColRow "^${ttc}=" ${mefl})")"
  gotHit="false"
  for at in ${allowedType[@]}; do
    #§echo ${at}
    if [ $(colTypeNotAllowed ${at} ${right}) == "true" ]
    then
      gotHit="true"
      #echo $at
    else
      :
    fi
  done
  if [ ${gotHit} == "false" ]
  then
    echo >&2 "colType not allowed for: ${ttc}="; 
    noError=false
  else
    :
  fi
done


#Do all col<var> names - not marked missing - exist in the header of the complementary sumstat file
#header=($(zcat sorted_row_index_sumstat_1.txt.gz | head -n1 | head -c -2))
function existInHeader(){
  if echo ${2} | grep -Pq "${1}"
  then
      echo true
  else
      echo false
  fi
}

for var in ${colNeeded2[@]}; do
  right="$(selRightHand "$(selColRow "^${var}=" ${mefl})")"
  if [ ${right} == "missing" ]
  then
    :
  else
    gotHit="false"
    for hc in ${header[@]}; do
      if [ $(existInHeader ${hc} ${right}) == "true" ]
      then
        gotHit="true"
        #echo $hc
      else
        :
      fi
    done
    if [ ${gotHit} == "false" ]
    then
      echo >&2 "colType not found in header: ${var}=${right}"; 
      noError=false
    else
      :
    fi
  fi
done

#Do we have a minimum set of col<var> names - to run the cleansumstats pipeline
#colCHR and colPOS must both exist
locColNeeded=(
colCHR
colPOS
)
for var in ${locColNeeded[@]}; do
  right="$(selRightHand "$(selColRow "^${var}=" ${mefl})")"
  if [ ${right} == "missing" ]
  then
      echo >&2 "colType cannot be set to missing: ${var}=${right}"; 
      noError=false
  else
    :
  fi
done

#at least colA1 must exist
alleleColNeeded=(
colA1
)
for var in ${alleleColNeeded[@]}; do
  right="$(selRightHand "$(selColRow "^${var}=" ${mefl})")"
  if [ ${right} == "missing" ]
  then
      echo >&2 "colType cannot be set to missing: ${var}=${right}"; 
      noError=false
  else
    :
  fi
done

#at least these combinations must exist (i.e., not being random)
#statsColsNeeded=(
#"colBETA,colSE"
#"colOR,colSE"
#)
#
#gotHit="false"
#for var in ${statsColsNeeded[@]}; do
#  one="${var#*,}" 
#  two="${var%,*}" 
#  right1="$(selRightHand "$(selColRow "^${one}=" ${mefl})")"
#  right2="$(selRightHand "$(selColRow "^${two}=" ${mefl})")"
#  if [ ${right1} == "missing" ] || [ ${right2} == "missing" ]
#  then
#    :
#  else
#    gotHit="true"
#  fi
#done
#if [ ${gotHit} == "false" ]
#then
#  echo >&2 "at least 1 of the req. stat pairs has to be non-missing in metafile"; 
#  noError=false
#else
#  :
#fi
if [ "${noError}" == "true" ]
then
  echo >&2 "all seems ok with the meta data format"
  exit 0
else
  echo >&2 "one or more problems detected with the meta data format"
  exit 1
fi
