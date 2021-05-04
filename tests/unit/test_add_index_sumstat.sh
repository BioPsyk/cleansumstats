#!/usr/bin/env bash

set -euo pipefail

test_script="add_sorted_rowindex_to_sumstat"
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
  "${test_script}.sh" ./input.yaml > ./observed-result.yaml

  _check_results ./observed-result.yaml ./expected-result.yaml

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Check that index are added as first column and sorted by LC_ALL=C

_setup "Add index and sort LC_ALL=C"

cat <<EOF > ./input.yaml
SNP	CHR	BP	A1	A2	FREQ_A1	EFFECT_A1	SE	P
rs6439928	chr3	141663261	T	C	0.658	-0.0157	0.0141	0.2648
rs6463169	chr7	42980893	T	C	0.825	-0.0219	0.0171	0.2012
rs6831643	chr4	99833465	T	C	0.669	-0.0321	0.0137	0.0193
rs10197378	chr2	29092758	A	G	0.183	-0.0189	0.0155	0.2226
rs10021082	chr4	100801356	T	C	0.958	0.0319	0.0264	0.2265
rs12709653	chr18	27735538	A	G	0.775	-0.0142	0.0142	0.3176
rs12726220	chr1	150984623	A	G	0.948	-0.0315	0.0277	0.2547
rs12739293	chr1	118812591	T	C	0.133	0.007	0.0175	0.6873
rs12754538	chr1	8408079	T	C	0.308	-6e-04	0.015	0.9663
rs12755429	chr1	31361128	T	C	0.802	0.0075	0.0171	0.6612
EOF

cat <<EOF > ./expected-result.yaml
0	SNP	CHR	BP	A1	A2	FREQ_A1	EFFECT_A1	SE	P
1	rs6439928	chr3	141663261	T	C	0.658	-0.0157	0.0141	0.2648
10	rs12755429	chr1	31361128	T	C	0.802	0.0075	0.0171	0.6612
2	rs6463169	chr7	42980893	T	C	0.825	-0.0219	0.0171	0.2012
3	rs6831643	chr4	99833465	T	C	0.669	-0.0321	0.0137	0.0193
4	rs10197378	chr2	29092758	A	G	0.183	-0.0189	0.0155	0.2226
5	rs10021082	chr4	100801356	T	C	0.958	0.0319	0.0264	0.2265
6	rs12709653	chr18	27735538	A	G	0.775	-0.0142	0.0142	0.3176
7	rs12726220	chr1	150984623	A	G	0.948	-0.0315	0.0277	0.2547
8	rs12739293	chr1	118812591	T	C	0.133	0.007	0.0175	0.6873
9	rs12754538	chr1	8408079	T	C	0.308	-6e-04	0.015	0.9663
EOF

_run_script

#---------------------------------------------------------------------------------
# Next case template

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
