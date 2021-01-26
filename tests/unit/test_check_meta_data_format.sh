#!/usr/bin/env bash

set -euo pipefail

test_script="check_meta_data_format"
initial_dir=$(pwd)"/${test_script}"
curr_case=""

mkdir "${initial_dir}"
cd "${initial_dir}"

#=================================================================================
# Helpers
#=================================================================================

function _setup {
  mkdir "${1}"
  cd "${1}"
  curr_case="${1}"
}

function _run_script_should_fail {
  script_result=$("${test_script}.sh" ./metadata.txt ./header.txt ./result.log 2>&1 >/dev/null; echo $?)

  if [[ "${script_result}" == 0 ]]; then
    echo "- [FAIL] ${curr_case}: Expected script to fail, but it was successful:"
    cat ./result.log
    exit 2
  fi

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

function _run_script {
  script_result=$("${test_script}.sh" ./metadata.txt ./header.txt ./result.log; echo $?)
  grep_result=$(grep "fail" ./result.log; echo $?)

  if [[ "${script_result}" != 0 || "${grep_result}" == 0 ]]; then
    echo "- [FAIL] ${curr_case}: Script exited with ${script_result}:"
    cat ./result.log
    exit 2
  fi

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

function _write_valid_metadata {
  cat <<EOF > ./metadata.txt
stats_Notes=Notes about stats
stats_GCValue=3.50
stats_GCMethod=astrology
stats_ControlN=23
stats_CaseN=2
stats_TotalN=25
stats_Model=Jepp
stats_TraitType=Stuff
study_Notes=No, I forgot take notes in class
study_Array=the best one
study_ImputeSoftware=Dog9.0
study_ImputePanel=ikea
study_PhaseSoftware=Cat1.5
study_PhasePanel=starbucks
study_Gender=missing
study_Ancestry=MARS
study_inHouseData=oASTRO
study_Restrictions=Can only be used when the planets are aligned
study_Contact=Andrew.Schork@regionh.dk
study_Controller=www.biorxiv.org/content/10.1101/240911v1
study_Use=open
study_AccessDate=2020_01_20
study_FileURL=asdad
study_FilePortal=asdad
study_PhenoCode=asdad
study_PhenoDesc=asdad
study_Year=2020
study_PMID=2
path_supplementary=./supp.txt
path_pdf=./supp.pdf
path_readMe=./README.md
path_sumStats=./sumstats.txt.gz
cleansumstats_metafile_date=123121
cleansumstats_metafile_user=me
cleansumstats_version=1.0
col_Notes=notes
col_INFO=info
col_ControlN=ctrl
col_CaseN=case
col_N=n
col_Direction=dir
col_AFREQ=afreq
col_P=pval
col_Z=z
col_ORU95=or_upper
col_ORL95=or_lower
col_OR=or
col_SE=se
col_BETA=beta
col_EffectAllele=a1
col_OtherAllele=a2
col_SNP=snp
col_POS=pos
col_CHR=chr
col_OAF=missing
col_EAF=missing
EOF
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Using columns missing in header

_setup "missing_header_columns"
_write_valid_metadata

cat <<EOF > ./header.txt
chr  pos  snp  a1  a2  n  case  se  or  or_upper  or_lower  z
EOF

_run_script_should_fail

#---------------------------------------------------------------------------------
# Using only required columns

_setup "required_columns"
_write_valid_metadata

cat <<EOF > ./header.txt
chr  pos  snp  a1  a2  n  case  ctrl  info  dir  beta  se  or  or_upper  or_lower  z  pval  afreq  oaf  eaf
EOF

_run_script
