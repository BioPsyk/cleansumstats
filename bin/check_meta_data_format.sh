#!/usr/bin/env bash


mefl="$1"
hfile="$2"
OUT_log="$3"
#metatempl="$3"

#if [ $# -eq 3 ] ; then
#  dirout=$3
#  OUT_log="${dirout}/check_meta_formatting.log"
#else
#  OUT_log="check_meta_formatting.log"
#fi

dat="$(date)"

#Hard coded requirements
#reporter variable
noError=true

# Does all important tags exist in the metadatafile
colNeededInMeta=(
version
run_user
run_date
path_sumStats
path_readMe
path_pdf
path_pdfSupp
study_PMID
study_Year
study_PhenoDesc
study_PhenoCode
study_PhenoMod
study_FilePortal
study_FileURL
study_AccessDate
study_Use
study_Controller
study_Contact
study_Restrictions
study_inHouseData
study_Ancestry
study_Gender
study_PhasePanel
study_PhaseSoftware
study_ImputePanel
study_ImputeSoftware
study_Array
study_Notes
stats_TraitType
stats_Model
stats_TotalN
stats_CaseN
stats_ControlN
stats_GCMethod
stats_GCValue
stats_Notes
col_CHR
col_POS
col_SNP
col_EffectAllele
col_OtherAllele
col_BETA
col_SE
col_OR
col_ORL95
col_ORU95
col_Z
col_P
col_N
col_CaseN
col_ControlN
col_AFREQ
col_INFO
col_Direction
col_Notes

)

colNeededInMetaCanHaveMultipleLines=(
path_pdfSupp
)

# A set without the types
colNeededInHeader=(
col_CHR
col_POS
col_SNP
col_EffectAllele
col_OtherAllele
col_BETA
col_SE
col_OR
col_ORL95
col_ORU95
col_Z
col_P
col_N
col_CaseN
col_ControlN
col_AFREQ
col_INFO
col_Direction
)


#examples of pattern types
#chr1:1324324
#1:3434324
#1_34235432_A_T
allowedType=(
'^[c|C][h|H][r|R]\d+$'
'^\d{1,2}[:_]\d+$'
'^\d{1,2}[:_]\d+[:_]\D+![:_]$'
'^\d{1,2}[:_]\d+[:_]\D+[:_]\D+$'
'^[c|C][h|H][r|R]\d{1,2}[:_]\d+$'
'^[c|C][h|H][r|R]\d{1,2}[:_]\d+[:_]\D+![:_]$'
'^[c|C][h|H][r|R]\d{1,2}[:_]\d+[:_]\D[:_]\D+$'
'^\D+$'
'^\d+$'
)


#functions

function variableMissing(){
  if grep -Pq "${1}" ${2}
  then
      echo false
  else
      echo true
  fi
}

function variableMultiLine(){
  if $(grep -P "${1}" ${2} | wc -l | awk '{if($1>1){print "true"}else{print "false"}}' )
  then
      echo true
  else
      echo false
  fi
}


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

function existInHeader(){
  if echo ${2} | grep -q "${1}"
  then
      echo true
  else
      echo false
  fi
}

echo "" >> ${OUT_log} 2>&1
echo "init $dat" > ${OUT_log} 2>&1

echo "" >> ${OUT_log} 2>&1
echo "" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1
echo "check for all required params in metafile" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1

#check that there is no tab in file
if grep -Pq '\t' ${mefl}
then
  tab_in_meta_test_result1="fail"
else
  tab_in_meta_test_result1="ok"
fi

if [ $? == 0  ]; then
 tab_in_meta_test_result2="ok"
 echo "tab_in_meta_test-check1 ${tab_in_meta_test_result1}" >> ${OUT_log}
 echo "tab_in_meta_test-check2 ok" >> ${OUT_log}
else
 tab_in_meta_test_result2="fail"
 echo "tab_in_meta_test-check1 ${tab_in_meta_test_result1}" >> ${OUT_log}
 echo "tab_in_meta_test-check2 fail" >> ${OUT_log}
fi


echo "" >> ${OUT_log} 2>&1
echo "" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1
echo "get header in sstat zip file" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1
if [[ $hfile =~ \.gz$ ]]; then
  header=($(zcat $hfile | awk '
  function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
  function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
  function trim(s)  { return rtrim(ltrim(s)); }
  
  NR==1{tr=trim($0); print tr}'))
else 
  header=($(awk '
  function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
  function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
  function trim(s)  { return rtrim(ltrim(s)); }
  
  NR==1{tr=trim($0); print tr}' $hfile))
fi

#if previous command was successful
if [ $? == 0  ]; then
 gzipheadertest_result="ok"
 echo "gzip-header-check1 ok" >> ${OUT_log}
else
 gzipheadertest_result="fail"
 echo "gzip-header-check1 fail" >> ${OUT_log}
fi

echo "" >> ${OUT_log} 2>&1
echo "" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1
echo "check for all required params in metafile" >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1

#check that all required paramter names are present in metadata file
var_in_meta_test_result1=$(
  var_in_meta_test_resultx="ok"
  for var in ${colNeededInMeta[@]}; do
    if [ $(variableMissing "^${var}=" ${mefl}) == "true" ]
    then
      #echo >&2 "variable missing: ${var}="; 
      var_in_meta_test_resultx="fail"
    else
      :
    fi
  done
  echo $var_in_meta_test_resultx
)
if [ $? == 0  ]; then
 var_in_meta_test_result2="ok"
 echo "var_in_meta_test-check1 ${var_in_meta_test_result1}" >> ${OUT_log}
 echo "var_in_meta_test-check2 ok" >> ${OUT_log}
else
 var_in_meta_test_result2="fail"
 echo "var_in_meta_test-check1 ${var_in_meta_test_result1}" >> ${OUT_log}
 echo "var_in_meta_test-check2 fail" >> ${OUT_log}
fi

#check that all required paramter names are present in metadata file

var_in_meta_test_mutliline_result1=$(
  var_in_meta_test_mutliline_resultx="ok"
  for var in ${colNeededInMeta[@]}; do
    if [ $(variableMultiLine "^${var}=" ${mefl}) == "true" ]
    then
      exception=false
      for exceptionVar in ${colNeededInMetaCanHaveMultipleLines[@]}; do
        if [ "${exceptionVar}" ==  "${var}" ]
        then
          exception=true
        else
          :
        fi
      done 

      if ${exception}
      then
        :
      else
        #echo >&2 "variable is not allowed to have multiple lines: ${var}="; 
        var_in_meta_test_mutliline_resultx="fail"
      fi
    else
      :
    fi
  done
  echo $var_in_meta_test_mutliline_resultx
)
if [ $? == 0  ]; then
 var_in_meta_test_mutliline_result2="ok"
 echo "var_in_meta_test_multiline-check1 ${var_in_meta_test_mutliline_result1}" >> ${OUT_log}
 echo "var_in_meta_test_multiline-check2 ok" >> ${OUT_log}
else
 var_in_meta_test_mutliline_result2="fail"
 echo "var_in_meta_test_multiline-check1 ${var_in_meta_test_mutliline_result1}" >> ${OUT_log}
 echo "var_in_meta_test_multiline-check2 fail" >> ${OUT_log}
fi


#Do all col<var> names - not marked missing - exist in the header of the complementary sumstat file
#header=($(zcat sorted_row_index_sumstat_1.txt.gz | head -n1 | head -c -2))
var_in_header_test_result1=$(
  var_in_header_test_resultx="ok"
  for var in ${colNeededInHeader[@]}; do
    right="$(selRightHand "$(selColRow "^${var}=" ${mefl})")"
    if [ ${right} == "missing" ]
    then
      :
    else
      gotHit="false"
      for hc in ${header[@]}; do
        #echo $hc
        if [ $(existInHeader ${hc} ${right}) == "true" ]
        then
          gotHit="true"
        else
          :
        fi
      done
      if [ ${gotHit} == "false" ]
      then
        echo >&2 "colType not found in header: ${var}=${right}"; 
        var_in_header_test_resultx="fail"
      else
        :
      fi
    fi
  done
  echo ${var_in_header_test_resultx}
)

if [ $? == 0  ]; then
 var_in_header_test_result2="ok"
 echo "var_in_header_test-check1 ${var_in_header_test_result1}" >> ${OUT_log}
 echo "var_in_header_test-check2 ok" >> ${OUT_log}
else
 var_in_header_test_result2="fail"
 echo "var_in_header_test-check2 ${var_in_header_test_result1}" >> ${OUT_log}
 echo "var_in_header_test-check2 fail" >> ${OUT_log}
fi


#Do we have a minimum set of col<var> names - to run the cleansumstats pipeline
#col_CHR and col_POS must both exist or col_SNP must exist, which can be used instead
locColNeededA=(
col_CHR
col_POS
)
locColNeededB=(
col_SNP
)
min_var_required_resultA=$(
  min_var_required_resultx="ok"
  for var in ${locColNeededA[@]}; do
    right="$(selRightHand "$(selColRow "^${var}=" ${mefl})")"
    if [ ${right} == "missing" ]
    then
        #echo >&2 "colType cannot be set to missing: ${var}=${right}"; 
        min_var_required_resultx="fail"
    else
      :
    fi
  done
  echo $min_var_required_resultx
)
if [ $? == 0  ]; then
 min_var_funx_test1="ok"
fi

min_var_required_resultB=$(
  min_var_required_resultx="ok"
  for var in ${locColNeededB[@]}; do
    right="$(selRightHand "$(selColRow "^${var}=" ${mefl})")"
    if [ ${right} == "missing" ]
    then
        #echo >&2 "colType cannot be set to missing: ${var}=${right}"; 
        min_var_required_resultx="fail"
    else
      :
    fi
  done
  echo $min_var_required_resultx
)
if [ $? == 0  ]; then
 min_var_funx_test2="ok"
fi

min_var_required_result1=$(

  if [ "${min_var_required_resultA}" == "ok" ]
  then
    result="ok"
  elif [ "${min_var_required_resultB}" == "ok" ]
  then
    result="ok"
  else
    echo >&2 "col_CHR and col_POS, or col_SNP cant be set to missing"; 
    result="fail"
  fi
  echo "${result}"
)

if [ $? == 0  ]; then
 min_var_funx_test3="ok"
fi

echo "min_var_required-check1 ${min_var_required_result1}" >> ${OUT_log}
echo "min_var_required-check2 ${min_var_funx_test1}" >> ${OUT_log}
echo "min_var_required-check3 ${min_var_funx_test2}" >> ${OUT_log}
echo "min_var_required-check4 ${min_var_funx_test3}" >> ${OUT_log}

#at least colA1 must exist
alleleColNeeded=(
col_EffectAllele
)

min_var_required_result3=$(
  min_var_required_resultx="ok"
  for var in ${alleleColNeeded[@]}; do
    right="$(selRightHand "$(selColRow "^${var}=" ${mefl})")"
    if [ ${right} == "missing" ]
    then
        #echo >&2 "colType cannot be set to missing: ${var}=${right}"; 
        min_var_required_resultx="fail"
    else
      :
    fi
  done
  echo $min_var_required_resultx
)

if [ $? == 0  ]; then
 min_var_required_result4="ok"
 echo "min_var_required-check3 ${min_var_required_result3}" >> ${OUT_log}
 echo "min_var_required-check4 ok" >> ${OUT_log}
else
 min_var_required_test_result4="fail"
 echo "min_var_required-check3 ${min_var_required_result3}" >> ${OUT_log}
 echo "min_var_required-check4 fail" >> ${OUT_log}
fi

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

if [ $gzipheadertest_result == "ok" ] && [ $var_in_meta_test_result1 == "ok" ] && [ $var_in_meta_test_result2 == "ok" ] && [ $var_in_header_test_result1 == "ok" ] && [ $var_in_header_test_result2 == "ok" ] && [ $min_var_required_result1 == "ok" ] && [ ${min_var_funx_test1} == "ok" ] && [ ${min_var_funx_test2} == "ok" ] && [ ${min_var_funx_test3} == "ok" ] && [ $min_var_required_result3 == "ok" ] && [ $min_var_required_result4 == "ok" ] && [ "${var_in_meta_test_mutliline_result1}" == "ok" ] && [ "${var_in_meta_test_mutliline_result2}" == "ok" ] && [ "${tab_in_meta_test_result1}" == "ok" ] && [ "${tab_in_meta_test_result2}" == "ok" ]
then
  test_set="ok"
else
  test_set="fail"
fi

echo "" >> ${OUT_log} 2>&1
echo "" >> ${OUT_log} 2>&1

if [ $test_set == "ok" ]; then

echo "##############################" >> ${OUT_log} 2>&1
echo "All checks for metafile ok " >> ${OUT_log} 2>&1
echo "##############################" >> ${OUT_log} 2>&1

else
  echo "something failed during tests" >> ${OUT_log}
 echo "gzip-header-check1 ${gzipheadertest_result}" >> ${OUT_log}
 echo "var_in_meta_test-check1 ${var_in_meta_test_result1}" >> ${OUT_log}
 echo "var_in_meta_test-check2 ${var_in_meta_test_result2}" >> ${OUT_log}
 echo "var_in_header_test-check1 ${var_in_header_test_result1}" >> ${OUT_log}
 echo "var_in_header_test-check2 ${var_in_header_test_result2}" >> ${OUT_log}
 echo "min_var_required-check1 ${min_var_required_result1}" >> ${OUT_log}
 echo "min_var_funx_test1 ${min_var_funx_test1}" >> ${OUT_log}
 echo "min_var_funx_test2 ${min_var_funx_test2}" >> ${OUT_log}
 echo "min_var_funx_test3 ${min_var_funx_test3}" >> ${OUT_log}
 echo "min_var_required-check3 ${min_var_required_result3}" >> ${OUT_log}
 echo "min_var_required-check4 ${min_var_required_result4}" >> ${OUT_log}
 echo "multiline-check1 ${var_in_meta_test_mutliline_result1}" >> ${OUT_log}
 echo "multiline-check2 ${var_in_meta_test_mutliline_result2}" >> ${OUT_log}
 echo "tab-check1 ${tab_in_meta_test_result1}" >> ${OUT_log}
 echo "tab-check2 ${tab_in_meta_test_result2}" >> ${OUT_log}
fi

if [ $test_set == "ok" ]
then
  #echo >&2 "all seems ok with the meta data format"
  exit 0
else
  echo >&2 "one or more problems detected with the meta data format"
  exit 1
fi
