#!/usr/bin/env bash

set -euo pipefail

test_script="make_metafile_unix_friendly"
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

  echo "- [OK] ${curr_case}"
}

function _run_script {
  "${test_script}.sh" ./input.yaml ./observed-result.yaml

  _check_results ./observed-result.yaml ./expected-result.yaml

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Check that the return \r characters are removed

_setup "remove windows return characters"

cat <<EOF > ./input.yaml
cleansumstats_metafile_date: '2020-04-27'\r
cleansumstats_metafile_user: Andrew Schork\r
cleansumstats_version: 1.0.0-alpha\r
col_AFREQ: FREQ_A1
EOF

cat <<EOF > ./expected-result.yaml
cleansumstats_metafile_date: '2020-04-27'
cleansumstats_metafile_user: Andrew Schork
cleansumstats_version: 1.0.0-alpha
col_AFREQ: FREQ_A1
EOF


_run_script

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
