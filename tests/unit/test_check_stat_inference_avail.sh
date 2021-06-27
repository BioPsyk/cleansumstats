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
}

function _check_results {
  obs=$1
  exp=$2
  if ! diff ${obs} ${exp} &> ./difference; then
    echo "- [FAIL] ${curr_case}"
    cat ./difference 
    exit 1
  fi
}

function _run_script {

  "${test_script}.sh" ./mfile.yaml ./colfields.txt ./colnames.txt ./colpositions.txt "branchX"

  _check_results ./colfields.txt ./expected-colfields.txt
  _check_results ./colnames.txt ./expected-colnames.txt
  _check_results ./colpositions.txt ./expected-colpositions.txt

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Case 1

_setup "input P, SE, OR, logistic regression"

cat <<EOF > ./mfile.yaml
col_P: p
col_SE: se
col_OR: or
EOF

cat <<EOF > ./expected-colfields.txt
0|se|p|or
EOF

cat <<EOF > ./expected-colpositions.txt
--index 1 --standarderror 2 --pvalue 3 --oddsratio 4
EOF

cat <<EOF > ./expected-colnames.txt
0,se,p,or
EOF


_run_script

#---------------------------------------------------------------------------------
# Case 2

