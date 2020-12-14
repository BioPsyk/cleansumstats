#!/usr/bin/env bash

set -euo pipefail

test_script="create_output_meta_data_file_rerun"
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
  set +e

  "${test_script}.sh" ./metadata.txt ./replace-extend.txt > ./result
  script_result="$?"

  if [[ "${script_result}" != 0 ]]; then
    echo "- [FAIL] ${curr_case}: Script exited with: ${script_result}"
    exit 1
  fi

  diff -u ./expected_result ./result

  if [[ "$?" != 0 ]]; then
    echo "[FAIL] ${curr_case}: Unexpected result"
    exit 1
  fi

  set -e

  echo "- [OK] ${curr_case}"
  cd "${initial_dir}"
}

function _write_valid_metadata {
  cat <<EOF > ./metadata.txt
path_sumStats=missing
path_readMe=readme.md
path_pdf=missing
cleansumstats_metafile_checksum_user=userchecksum
cleansumstats_sumstat_checksum_raw=rawchecksum
study_PMID=2
study_Year=2020
study_PhenoDesc=asdad
study_PhenoCode=asdad
study_FilePortal=asdad
study_FileURL=asdad
study_AccessDate=2020_01_20
study_Use=open
study_Controller=www.biorxiv.org/content/10.1101/240911v1
study_Contact=Andrew.Schork@regionh.dk
study_Restrictions=Can only be used when the planets are aligned
study_inHouseData=oASTRO
study_Ancestry=MARS
study_Gender=missing
study_PhasePanel=starbucks
study_PhaseSoftware=Cat1.5
study_ImputePanel=ikea
study_ImputeSoftware=Dog9.0
study_Array=the best one
study_Notes=No, I forgot take notes in class
stats_TraitType=Stuff
stats_Model=Jepp
stats_TotalN=25
stats_CaseN=2
stats_ControlN=23
stats_EffectiveN=21
stats_GCMethod=astrology
stats_GCValue=3.50
stats_Notes=Notes about stats
col_CHR=chr
col_POS=pos
col_SNP=snp
col_EffectAllele=a1
col_OtherAllele=a2
col_BETA=b
col_SE=se
col_OR=or
col_ORL95=orl95
col_ORU95=oru95
col_Z=z
col_P=pval
col_N=n
col_CaseN=case_n
col_ControlN=control_n
col_EAF=ea
col_INFO=info
col_Direction=dir
col_Notes=notes
EOF
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Using all needed fields

_setup "all_needed"

_write_valid_metadata

echo "cleansumstats_metafile_user=jesgad" >> ./metadata.txt

cat <<EOF > ./replace-extend.txt
path_sumStats=mysumstats.txt.gz
study_Use=private
EOF

cat <<EOF > ./expected_result
path_sumStats=mysumstats.txt.gz
path_readMe=readme.md
path_pdf=missing
cleansumstats_metafile_checksum_user=userchecksum
cleansumstats_sumstat_checksum_raw=rawchecksum
study_PMID=2
study_Year=2020
study_PhenoDesc=asdad
study_PhenoCode=asdad
study_FilePortal=asdad
study_FileURL=asdad
study_AccessDate=2020_01_20
study_Use=private
study_Controller=www.biorxiv.org/content/10.1101/240911v1
study_Contact=Andrew.Schork@regionh.dk
study_Restrictions=Can only be used when the planets are aligned
study_inHouseData=oASTRO
study_Ancestry=MARS
study_Gender=missing
study_PhasePanel=starbucks
study_PhaseSoftware=Cat1.5
study_ImputePanel=ikea
study_ImputeSoftware=Dog9.0
study_Array=the best one
study_Notes=No, I forgot take notes in class
stats_TraitType=Stuff
stats_Model=Jepp
stats_TotalN=25
stats_CaseN=2
stats_ControlN=23
stats_EffectiveN=21
stats_GCMethod=astrology
stats_GCValue=3.50
stats_Notes=Notes about stats
col_CHR=chr
col_POS=pos
col_SNP=snp
col_EffectAllele=a1
col_OtherAllele=a2
col_BETA=b
col_SE=se
col_OR=or
col_ORL95=orl95
col_ORU95=oru95
col_Z=z
col_P=pval
col_N=n
col_CaseN=case_n
col_ControlN=control_n
col_EAF=ea
col_INFO=info
col_Direction=dir
col_Notes=notes
cleansumstats_metafile_user=jesgad
EOF

_run_script
