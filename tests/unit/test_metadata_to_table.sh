#!/usr/bin/env bash

set -euo pipefail

test_script="metadata_to_table"
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

function _check_results {
  if ! diff "./result" "./expected" &> ./difference; then
    echo "- [FAIL] ${curr_case}"
    git diff --word-diff=color --word-diff-regex=. "./expected" "./result"
    exit 1
  fi
}

function _run_script {
  "${test_script}.py" --log_level=debug "$@" > ./result

  _check_results

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Case 1 - using a single metadata file

_setup "single file"

cat <<EOF > ./metadata.yaml
cleansumstats_version: 1.0.0
study_Use: open
EOF

cat <<EOF > ./expected
metadata_dir,cleansumstats_version,cleansumstats_metafile_user,cleansumstats_metafile_date,cleansumstats_metafile_kind,path_sumStats,path_readMe,path_pdf,path_supplementary,study_Title,study_PMID,study_Year,study_PhenoDesc,study_PhenoCode,study_FilePortal,study_FileURL,study_AccessDate,study_Use,study_includedCohorts,study_Ancestry,study_Gender,study_PhasePanel,study_PhaseSoftware,study_ImputePanel,study_ImputeSoftware,study_Array,study_Notes,stats_TraitType,stats_Model,stats_TotalN,stats_CaseN,stats_ControlN,stats_GCMethod,stats_GCValue,stats_Notes,col_CHR,col_POS,col_SNP,col_EffectAllele,col_OtherAllele,col_BETA,col_SE,col_OR,col_ORL95,col_ORU95,col_Z,col_P,stats_neglog10P,col_N,col_CaseN,col_ControlN,col_StudyN,col_INFO,col_EAF,col_OAF,col_Direction,col_Notes
single file,1.0.0,,,,,,,,,,,,,,,,open,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
EOF

_run_script ./metadata.yaml

#---------------------------------------------------------------------------------
# Case 2 - using a multiple metadata files

_setup "multiple files"

cat <<EOF > ./metadata1.yaml
cleansumstats_version: 1.0.0
study_Use: open
EOF

cat <<EOF > ./metadata2.yaml
cleansumstats_version: 1.0.0
cleansumstats_metafile_user: riczet
study_Use: restricted
EOF

cat <<EOF > ./expected
metadata_dir,cleansumstats_version,cleansumstats_metafile_user,cleansumstats_metafile_date,cleansumstats_metafile_kind,path_sumStats,path_readMe,path_pdf,path_supplementary,study_Title,study_PMID,study_Year,study_PhenoDesc,study_PhenoCode,study_FilePortal,study_FileURL,study_AccessDate,study_Use,study_includedCohorts,study_Ancestry,study_Gender,study_PhasePanel,study_PhaseSoftware,study_ImputePanel,study_ImputeSoftware,study_Array,study_Notes,stats_TraitType,stats_Model,stats_TotalN,stats_CaseN,stats_ControlN,stats_GCMethod,stats_GCValue,stats_Notes,col_CHR,col_POS,col_SNP,col_EffectAllele,col_OtherAllele,col_BETA,col_SE,col_OR,col_ORL95,col_ORU95,col_Z,col_P,stats_neglog10P,col_N,col_CaseN,col_ControlN,col_StudyN,col_INFO,col_EAF,col_OAF,col_Direction,col_Notes
multiple files,1.0.0,,,,,,,,,,,,,,,,open,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
multiple files,1.0.0,riczet,,,,,,,,,,,,,,,restricted,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
EOF

_run_script *.yaml

#---------------------------------------------------------------------------------
# Case 3 - using a multiple metadata files with list values

_setup "multiple files, list values"

cat <<EOF > ./metadata1.yaml
cleansumstats_version: 1.0.0
study_Use: open
study_PhenoCode: ["EFO:0000289", "EFO:0009963"]
EOF

cat <<EOF > ./metadata2.yaml
cleansumstats_version: 1.0.0
cleansumstats_metafile_user: riczet
study_Use: restricted
study_includedCohorts:
  - "iPSYCH2012"
  - "iPSYCH2015"
EOF

cat <<EOF > ./expected
metadata_dir,cleansumstats_version,cleansumstats_metafile_user,cleansumstats_metafile_date,cleansumstats_metafile_kind,path_sumStats,path_readMe,path_pdf,path_supplementary,study_Title,study_PMID,study_Year,study_PhenoDesc,study_PhenoCode,study_FilePortal,study_FileURL,study_AccessDate,study_Use,study_includedCohorts,study_Ancestry,study_Gender,study_PhasePanel,study_PhaseSoftware,study_ImputePanel,study_ImputeSoftware,study_Array,study_Notes,stats_TraitType,stats_Model,stats_TotalN,stats_CaseN,stats_ControlN,stats_GCMethod,stats_GCValue,stats_Notes,col_CHR,col_POS,col_SNP,col_EffectAllele,col_OtherAllele,col_BETA,col_SE,col_OR,col_ORL95,col_ORU95,col_Z,col_P,stats_neglog10P,col_N,col_CaseN,col_ControlN,col_StudyN,col_INFO,col_EAF,col_OAF,col_Direction,col_Notes
"multiple files, list values",1.0.0,,,,,,,,,,,,"EFO:0000289,EFO:0009963",,,,open,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
"multiple files, list values",1.0.0,riczet,,,,,,,,,,,,,,,restricted,"iPSYCH2012,iPSYCH2015",,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
EOF

_run_script *.yaml
