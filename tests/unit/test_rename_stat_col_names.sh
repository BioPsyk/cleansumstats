#!/usr/bin/env bash

set -euo pipefail

test_script="rename_stat_col_names"
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
  "${test_script}.sh" ./stat.tsv \
    "EFFECT_A1" \
    "SE" \
    "Z" \
    "PX" \
    "missing" \
    "missing" \
    "missing" \
    "missing" \
    "missing" \
    "missing" \
    "missing" \
    "missing" \
    "missing" \
    "EAF" \
    "missing" \
    "missing" \
    "missing" \
    "missing" \
    "missing" \
    > ./observed-result1.txt

  _check_results ./observed-result1.txt ./expected-result1.tsv

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Case 1

_setup "renaming PX, SE, EFFECT_A1, Z, EAF"

cat <<EOF > ./stat.tsv
0	EFFECT_A1	SE	Z	PX	EAF
1	-0.0143	0.0156	-0.916667	0.3604	0.373
EOF

cat <<EOF > ./expected-result1.tsv
0	B	SE	Z	P	EAF
1	-0.0143	0.0156	-0.916667	0.3604	0.373
EOF

_run_script

