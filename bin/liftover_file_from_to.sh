#!/usr/bin/env bash

# NOTE: In the R script at the core of sstools-gb liftover there is a filter removing all chromosomes that are not 1-22

FILE_PATH=${1}
FROM=${2}
TO=${3}
NR=${4}

if [ ${FROM} == "GRCh38" ] && [ ${TO} == "GRCh38" ]
then
  if [ ${NR} == "all" ]
  then
    cat ${FILE_PATH} 
  else                                                                                                                
    cat ${FILE_PATH} | head -n${NR} 
  fi
else                                                                                                                
  if [ ${NR} == "all" ]
  then
    cat ${FILE_PATH} | sstools-gb liftover -f - -g ${FROM} -q ${TO} -s 10000 -i "chrpos=1,inx=2" 
  else                                                                                                                
    cat ${FILE_PATH} | head -n${NR} | sstools-gb liftover -f - -g ${FROM} -q ${TO} -s 10000 -i "chrpos=1,inx=2" 
  fi
fi

