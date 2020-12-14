#!/usr/bin/env bash

set -euo pipefail

test_script="create_output_meta_data_file_cleaned"
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

  "${test_script}.sh" ./metadata.txt ./header.txt > ./result
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

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Using lin model with all statistical variables existing

_setup "lin_all"

cat <<EOF > ./metadata.txt
col_BETA=b
col_SE=se
col_Z=z
col_P=p
col_OR=or
col_N=n
col_EAF=eaf
col_OAF=oaf
col_ORL95=orl95
col_ORU95=oru95
col_CaseN=case_n
col_ControlN=ctrl_n
col_INFO=info
col_Direction=dir
stats_Model=lin
EOF

cat <<EOF > ./header.txt
B	SE	OR	ORL95	ORU95	Z	P	N	CaseN	ControlN	EAF	INFO	Direction
EOF

cat <<EOF > ./expected_result
col_BETA=b
col_SE=se
col_Z=z
col_P=p
col_OR=or
col_N=n
col_EAF=eaf
col_OAF=oaf
col_ORL95=orl95
col_ORU95=oru95
col_CaseN=case_n
col_ControlN=ctrl_n
col_INFO=info
col_Direction=dir
stats_Model=lin
cleansumstats_col_RAWROWINDEX=0
cleansumstats_col_CHR=CHR
cleansumstats_col_POS=POS
cleansumstats_col_SNP=RSID
cleansumstats_col_EffectAllele=EffectAllele
cleansumstats_col_OtherAllele=OtherAllele
cleansumstats_col_BETA=missing
cleansumstats_col_SE=missing
cleansumstats_col_OR=missing
cleansumstats_col_ORL95=missing
cleansumstats_col_ORU95=missing
cleansumstats_col_Z=missing
cleansumstats_col_P=missing
cleansumstats_col_N=missing
cleansumstats_col_CaseN=CaseN
cleansumstats_col_ControlN=ControlN
cleansumstats_col_EAF=missing
cleansumstats_col_INFO=missing
cleansumstats_col_Direction=Direction
cleansumstats_col_Notes=If possible, missing stats have been calculated from the avialable. If OtherAllele was missing we use the alternate allele according to the dbsnp reference
EOF

_run_script
