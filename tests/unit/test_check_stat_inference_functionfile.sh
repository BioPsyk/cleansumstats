#!/usr/bin/env bash

set -euo pipefail

test_script="check_stat_inference_functionfile"
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

  "${test_script}.sh" ./metadata.txt "${1}" > ./result
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
# Using logM model with P, OR and N

_setup "log_m_p_or_n"

cat <<EOF > ./metadata.txt
col_BETA=missing
col_SE=missing
col_Z=missing
col_P=p
col_OR=or
col_N=n
col_EAF=eaf
col_OAF=oaf
stats_Model=logM
EOF

cat <<EOF > ./expected_result
EOF

_run_script ""

#---------------------------------------------------------------------------------
# Using lin model with all present

_setup "lin_b_p_or_n"

cat <<EOF > ./metadata.txt
col_BETA=b
col_SE=se
col_Z=z
col_P=p
col_OR=or
col_N=n
col_EAF=eaf
col_OAF=oaf
stats_Model=lin
EOF

cat <<EOF > ./expected_result
EOF

_run_script ""
