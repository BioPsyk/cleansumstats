#!/usr/bin/env bash

set -euo pipefail

test_script="check_and_format_sfile"
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
  gzip --keep ./sumstat.txt

  "${test_script}.sh" ./sumstat.txt.gz ./result.tsv ./result.log

  result=$(grep "fail" ./result.log; echo $?)

  if [[ "${result}" == 0 ]]; then
    echo "- [FAIL] ${curr_case}: Found failure in log-file:"
    cat ./result.log
    exit 2
  fi

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Using valid space separated input

_setup "valid_space_separated"

cat <<EOF > ./sumstat.txt
0    A1    A2    CHRPOS    RSID    EffectAllele    OtherAllele    EMOD
1    A    G    12:126406434    rs1000000    G    A    -1
EOF

_run_script

#---------------------------------------------------------------------------------
# Using valid tab separated input

_setup "valid_tab_separated"

cat <<EOF > ./sumstat.txt
0			A1			A2			CHRPOS			RSID			EffectAllele			OtherAllele			EMOD
1			A			G			12:126406434			rs1000000			G			A			-1
EOF

_run_script
