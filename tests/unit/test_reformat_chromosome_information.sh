#!/usr/bin/env bash

set -euo pipefail

test_script="reformat_chromosome_information"
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
  filterType=$1

  "${test_script}.sh" ./input.tsv ${filterType} ./observed-result1.tsv ./observed-result2.tsv ./observed-result3.tsv

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
# Check that the duplicated row gets filtered out in the right way. Right now keeping the first occurence and discarding the rest
# Interesting observation from manual testing is that sorting on column1 still use column2 do decide the order of duplicates
# In this case putting rowindex 703 above 1873 will create an error as the first thing in the filterScript is to do a LC_ALL=C sort -k1,1

_setup "Keep only first occurence for each chrpos key"

cat <<EOF > ./input.tsv
10:10035873	724
10:100577961	41
10:101337192	966
10:101907510	702
10:103716518	1873
10:103716518	703
10:106105537	1009
10:10656491	1582
10:107655108	1825
10:108072635	814
EOF

cat <<EOF > ./expected-result1.tsv
10:10035873	724
10:100577961	41
10:101337192	966
10:101907510	702
10:103716518	1873
10:106105537	1009
10:10656491	1582
10:107655108	1825
10:108072635	814
EOF

cat <<EOF > ./expected-result2.tsv
703	removed_duplicated_rows_dbsnpkeys
EOF

cat <<EOF > ./expected-result3.tsv
duplicated_dbsnpkey
EOF

_run_script "duplicated_keys"

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
