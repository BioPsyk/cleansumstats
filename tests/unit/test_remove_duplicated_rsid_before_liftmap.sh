#!/usr/bin/env bash

set -euo pipefail

test_script="remove_duplicated_rsid_before_liftmap"
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
  snpExists=$1
  filterType=$2

  "${test_script}.sh" ./input.tsv ${snpExists} ${filterType} ./observed-result1.tsv ./observed-result2.tsv ./observed-result3.tsv

  _check_results ./observed-result1.tsv ./expected-result1.tsv
  _check_results ./observed-result2.tsv ./expected-result2.tsv
  _check_results ./observed-result3.tsv ./expected-result3.tsv

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Check that the return \r characters are removed

_setup "Keep only first occurence for each rsid key"

cat <<EOF > ./input.tsv
RSID	0
rs1000014	817
rs1001127	710
rs10014954	823
rs10021082	1001
rs10021082	1063
rs10025483	1122
rs1003001	1261
rs10032088	1323
rs10034756	1433
EOF

cat <<EOF > ./expected-result1.tsv
RSID	0
rs1000014	817
rs1001127	710
rs10014954	823
rs10021082	1001
rs10025483	1122
rs1003001	1261
rs10032088	1323
rs10034756	1433
EOF

cat <<EOF > ./expected-result2.tsv
1063	removed_duplicated_rows_dbsnpkeys
EOF

cat <<EOF > ./expected-result3.tsv
duplicated_dbsnpkey
EOF

_run_script "true" "duplicated_keys"

#---------------------------------------------------------------------------------
# Next case

#_setup "valid_rows_missing_afreq"
#
#cat <<EOF > ./acor.tsv
#0	A1	A2	CHRPOS	RSID	EffectAllele	OtherAllele	EMOD
#1	A	G	12:126406434	rs1000000	G	A	-1
#EOF
#
#cat <<EOF > ./stat.tsv
#0	B	SE	Z	P
#1	-0.0143	0.0156	-0.916667	0.3604
#EOF
#
#_run_script
