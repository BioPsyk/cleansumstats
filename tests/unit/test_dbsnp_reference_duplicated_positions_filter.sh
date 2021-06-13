#!/usr/bin/env bash

set -euo pipefail

test_script="dbsnp_reference_duplicate_position_filter"
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

  "${test_script}.sh" ./input.txt ./observed-result1.txt

  _check_results ./observed-result1.txt ./expected-result1.txt

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Case 1 - the duplicates are in the end

_setup "duplicates in the end"

cat <<EOF > ./input.txt
chr22 19601090 19601090 22:19601090 22:19613567 rs1187200240 G A
chr10 10001040 10001040 10:10001040 10:15601264 rs1217200130 G A
chr22 19601090 19601090 22:19601090 22:19613567 rs119723084 G A
EOF

cat <<EOF > ./expected-result1.txt
chr10 10001040 10001040 10:10001040 10:15601264 rs1217200130 G A
EOF

_run_script

#---------------------------------------------------------------------------------
# Next case

_setup "duplicates in the beginning"

cat <<EOF > ./input.txt
chr2 19601090 19601090 2:19601090 2:19613567 rs1187200240 G A
chr10 10001040 10001040 10:10001040 10:15601264 rs1217200130 G A
chr2 19601090 19601090 2:19601090 2:19613567 rs119723084 G A
EOF

cat <<EOF > ./expected-result1.txt
chr10 10001040 10001040 10:10001040 10:15601264 rs1217200130 G A
EOF

_run_script

#---------------------------------------------------------------------------------
# Next case

_setup "duplicates in the middle"

cat <<EOF > ./input.txt
chr1 50001040 50001040 1:50001040 1:45601264 rs9017200130 G A
chr2 19601090 19601090 2:19601090 2:19613567 rs1187200240 G A
chr2 19601090 19601090 2:19601090 2:19613567 rs119723084 G A
chr10 10001040 10001040 10:10001040 10:15601264 rs1217200130 G A
EOF

cat <<EOF > ./expected-result1.txt
chr10 10001040 10001040 10:10001040 10:15601264 rs1217200130 G A
chr1 50001040 50001040 1:50001040 1:45601264 rs9017200130 G A
EOF

_run_script

#---------------------------------------------------------------------------------
# Next case

_setup "triplicates in the middle"

cat <<EOF > ./input.txt
chr1 50001040 50001040 1:50001040 1:45601264 rs9017200130 G A
chr2 19601090 19601090 2:19601090 2:19613567 rs1187200240 G A
chr2 19601090 19601090 2:19601090 2:19613567 rs119723084 G A
chr2 19601090 19601090 2:19601090 2:19613567 rs149723084 G A
chr10 10001040 10001040 10:10001040 10:15601264 rs1217200130 G A
EOF

cat <<EOF > ./expected-result1.txt
chr10 10001040 10001040 10:10001040 10:15601264 rs1217200130 G A
chr1 50001040 50001040 1:50001040 1:45601264 rs9017200130 G A
EOF

_run_script

