#!/usr/bin/env bash

set -euo pipefail

test_script="convert_neglogP"
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
  if ! diff -u ${obs} ${exp} &> ./difference; then
    echo "- [FAIL] ${curr_case}"
    cat ./difference 
    exit 1
  fi

}

function _run_script {
  col_P=$1

  "${test_script}.sh" ./input1.tsv ${col_P} > ./observed-result1.tsv

  _check_results ./observed-result1.tsv ./expected-result1.tsv

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# neglog conversion - case 1

_setup "Simple input"

cat <<EOF > ./input1.tsv
0	EFFECT_A1	SE	P
1	-0.0157	0.0141	0.5770820
10	-0.0219	0.0171	0.6963720
100	-0.0321	0.0137	1.7144427
1000	-0.0189	0.0155	0.6524748
1001	0.0319	0.0264	0.6449318
1002	-0.0142	0.0142	0.4981195
EOF

cat <<EOF > ./expected-result1.tsv
0	EFFECT_A1	SE	P
1	-0.0157	0.0141	2.64800e-01
10	-0.0219	0.0171	2.01200e-01
100	-0.0321	0.0137	1.93000e-02
1000	-0.0189	0.0155	2.22600e-01
1001	0.0319	0.0264	2.26500e-01
1002	-0.0142	0.0142	3.17600e-01
EOF

_run_script "P"

#---------------------------------------------------------------------------------
#  case 2

