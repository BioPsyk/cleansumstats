#!/usr/bin/env bash

set -euo pipefail

test_script="check_stat_inference_avail"
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
  touch ./colfields
  touch ./colnames
  touch ./colpositions
}

function _run_script {
  set +e

  "${test_script}.sh" ./metadata.txt ./colfields ./colnames ./colpositions
  script_result="$?"

  if [[ "${script_result}" != 0 ]]; then
    echo "- [FAIL] ${curr_case}: Script exited with: ${script_result}"
    exit 1
  fi

  diff -u ./expected_colfields ./colfields

  if [[ "$?" != 0 ]]; then
    echo "[FAIL] ${curr_case}: Unexpected colfields"
    exit 1
  fi

  diff -u ./expected_colnames ./colnames

  if [[ "$?" != 0 ]]; then
    echo "[FAIL] ${curr_case}: Unexpected colnames"
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
# Using metadata where EAF and OAF is marked missing

_setup "missing_eaf_and_oaf"

cat <<EOF > ./metadata.txt
col_BETA=b
col_SE=se
col_Z=z
col_P=p
col_OR=or
col_N=n
col_EAF=missing
col_OAF=missing
EOF

cat <<EOF > ./expected_colfields
0|b|se|z|p|or|n
EOF

cat <<EOF > ./expected_colnames
0,b,se,z,p,or,n
EOF

_run_script

#---------------------------------------------------------------------------------
# Using both EAF and OAF columns

_setup "existing_eaf_and_oaf"

cat <<EOF > ./metadata.txt
col_BETA=b
col_SE=se
col_Z=z
col_P=p
col_OR=or
col_N=n
col_EAF=eaf
col_OAF=oaf
EOF

cat <<EOF > ./expected_colfields
0|b|se|z|p|or|n|EAF
EOF

cat <<EOF > ./expected_colnames
0,b,se,z,p,or,n,EAF
EOF

_run_script

#---------------------------------------------------------------------------------
# Using all columns missing

_setup "all_missing"

cat <<EOF > ./metadata.txt
col_BETA=missing
col_SE=missing
col_Z=missing
col_P=missing
col_OR=missing
col_N=missing
col_EAF=missing
col_OAF=missing
EOF

cat <<EOF > ./expected_colfields
0
EOF

cat <<EOF > ./expected_colnames
0
EOF

_run_script
