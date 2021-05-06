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

  "${test_script}.sh" ./input.tsv ${snpExists} ./observed-result1.tsv ./observed-result2.tsv ${colSNP}

  _check_results ./observed-result1.tsv ./expected-result1.tsv
  _check_results ./observed-result2.tsv ./expected-result2.tsv

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

cat <<EOF > ./input.tsv
0	SNP	CHR	BP	A1	A2	FREQ_A1	EFFECT_A1	SE	P
1	rs6439928	chr3	141663261	T	C	0.658	-0.0157	0.0141	0.2648
10	rs6463169	chr7	42980893	T	C	0.825	-0.0219	0.0171	0.2012
100	rs6831643	chr4	99833465	T	C	0.669	-0.0321	0.0137	0.0193
1000	chr2:29092758	chr2	29092758	A	G	0.183	-0.0189	0.0155	0.2226
1001	chr4:100801356	chr4	100801356	T	C	0.958	0.0319	0.0264	0.2265
1002	rs12709653	chr18	27735538	A	G	0.775	-0.0142	0.0142	0.3176
EOF

cat <<EOF > ./expected-result1.tsv
RSID	0
rs6439928	1
rs6463169	10
rs6831643	100
rs12709653	1002
EOF

cat <<EOF > ./expected-result2.tsv
Markername	0
chr2:29092758	1000
chr4:100801356	1001
EOF

_run_script "true" "SNP"

#---------------------------------------------------------------------------------
# What if SNP column is set to missing

_setup "Handling missing SNP-column, colname 'missing' provided"

cat <<EOF > ./input.tsv
0	SNP	CHR	BP	A1	A2	FREQ_A1	EFFECT_A1	SE	P
1	rs6439928	chr3	141663261	T	C	0.658	-0.0157	0.0141	0.2648
10	rs6463169	chr7	42980893	T	C	0.825	-0.0219	0.0171	0.2012
100	rs6831643	chr4	99833465	T	C	0.669	-0.0321	0.0137	0.0193
1000	chr2:29092758	chr2	29092758	A	G	0.183	-0.0189	0.0155	0.2226
1001	chr4:100801356	chr4	100801356	T	C	0.958	0.0319	0.0264	0.2265
1002	rs12709653	chr18	27735538	A	G	0.775	-0.0142	0.0142	0.3176
EOF

cat <<EOF > ./expected-result1.tsv
RSID	0
EOF

cat <<EOF > ./expected-result2.tsv
Markername	0
EOF

_run_script "false" "missing"

#---------------------------------------------------------------------------------
# What if SNP column is not set at all

_setup "Handling missing SNP-column, no SNP colname provided"

cat <<EOF > ./input.tsv
0	SNP	CHR	BP	A1	A2	FREQ_A1	EFFECT_A1	SE	P
1	rs6439928	chr3	141663261	T	C	0.658	-0.0157	0.0141	0.2648
10	rs6463169	chr7	42980893	T	C	0.825	-0.0219	0.0171	0.2012
100	rs6831643	chr4	99833465	T	C	0.669	-0.0321	0.0137	0.0193
1000	chr2:29092758	chr2	29092758	A	G	0.183	-0.0189	0.0155	0.2226
1001	chr4:100801356	chr4	100801356	T	C	0.958	0.0319	0.0264	0.2265
1002	rs12709653	chr18	27735538	A	G	0.775	-0.0142	0.0142	0.3176
EOF

cat <<EOF > ./expected-result1.tsv
RSID	0
EOF

cat <<EOF > ./expected-result2.tsv
Markername	0
EOF

_run_script "false" ""

