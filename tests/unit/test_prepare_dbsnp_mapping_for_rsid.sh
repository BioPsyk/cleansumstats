#!/usr/bin/env bash

set -euo pipefail

test_script="prepare_dbsnp_mapping_for_rsid"
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
  colSNP=$2

  "${test_script}.sh" ./input.yaml ${snpExists} ${colSNP} ./observed-result1.yaml ./observed-result2.yaml

  _check_results ./observed-result1.yaml ./expected-result1.yaml
  _check_results ./observed-result2.yaml ./expected-result2.yaml

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Check that the return \r characters are removed

_setup "Split into rs and snpchros file"

cat <<EOF > ./input.yaml
0	SNP	CHR	BP	A1	A2	FREQ_A1	EFFECT_A1	SE	P
1	rs6439928	chr3	141663261	T	C	0.658	-0.0157	0.0141	0.2648
10	rs6463169	chr7	42980893	T	C	0.825	-0.0219	0.0171	0.2012
100	rs6831643	chr4	99833465	T	C	0.669	-0.0321	0.0137	0.0193
1000	chr2:29092758	chr2	29092758	A	G	0.183	-0.0189	0.0155	0.2226
1001	chr4:100801356	chr4	100801356	T	C	0.958	0.0319	0.0264	0.2265
1002	rs12709653	chr18	27735538	A	G	0.775	-0.0142	0.0142	0.3176
EOF

cat <<EOF > ./expected-result1.yaml
RSID	0
rs6439928	1
rs6463169	10
rs6831643	100
rs12709653	1002
EOF

cat <<EOF > ./expected-result2.yaml
Markername	0
chr2:29092758	1000
chr4:100801356	1001
EOF

_run_script "true" "SNP"

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
