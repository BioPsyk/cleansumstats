#!/usr/bin/env bash

set -euo pipefail

test_script="metadata_legacy_to_yaml"
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

function _run_script {
  "${test_script}.py" ./metadata.txt

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Using a simple metadata file

_setup "simple_valid"

cat <<EOF > ./metadata.txt
cleansumstats_metafile_date=2021-01-21
cleansumstats_metafile_user=riczet
cleansumstats_version=1.0.0-dev
col_CHR=chr
col_EffectAllele=a1
col_BETA=beta
col_N=n
col_OR=or
col_OtherAllele=a2
col_P=p
col_POS=bp
col_SE=se
path_sumStats=sumstats.txt.gz
study_Title=Test study
study_PMID=https://doi.org/10.1038/s41586-020-03160-0
study_Year=2021
study_PhenoDesc=blabla
study_AccessDate=2021-01-21
study_Use=open
study_Ancestry=EUR
study_Gender=mixed
study_Array=meta
stats_TraitType=quantitative
stats_Model=linear
stats_TotalN=1000
EOF

_run_script
