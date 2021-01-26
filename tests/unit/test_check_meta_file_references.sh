#!/usr/bin/env bash

set -euo pipefail

test_script="check_meta_file_references"
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
  mkdir references
}

function _run_script {
  script_result=$("${test_script}.sh" "${1}" ./metadata.txt ./references >/dev/null; echo $?)

  if [[ "${script_result}" != 0 ]]; then
    echo "- [FAIL] ${curr_case}: Script exited with: ${script_result}"
    exit 1
  fi

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

function _run_script_should_fail {
  script_result=$("${test_script}.sh" "${1}" ./metadata.txt ./references >/dev/null; echo $?)

  if [[ "${script_result}" == 0 ]]; then
    echo "- [FAIL] ${curr_case}: Expected script to fail: ${script_result}"
    exit 1
  fi

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Using missing field

_setup "missing_field"

cat <<EOF > ./metadata.txt
cleansumstats_metafile_user=riczet
cleansumstats_metafile_date=2021-01-13
path_sumStats=asd.txt.gz
path_readMe=readme.md
path_pdf=missing
col_EAF=missing
EOF

_run_script "path_pdf"

#---------------------------------------------------------------------------------
# Using field that points to file that exists

_setup "existing_file"

touch ./references/readme.md

cat <<EOF > ./metadata.txt
cleansumstats_metafile_user=jesgad
cleansumstats_metafile_date=2021-01-13
path_sumStats=missing
path_readMe=readme.md
path_pdf=missing
col_EAF=missing
EOF

_run_script "path_readMe"

#---------------------------------------------------------------------------------
# Using field that points to file that doesn't exist

_setup "missing_file"

cat <<EOF > ./metadata.txt
cleansumstats_metafile_user=andsch
cleansumstats_metafile_date=2021-01-13
path_sumStats=asd.txt.gz
path_readMe=readme.md
path_pdf=missing
col_EAF=missing
EOF

_run_script_should_fail "path_sumStats"
