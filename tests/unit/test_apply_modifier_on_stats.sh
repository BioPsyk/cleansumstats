#!/usr/bin/env bash

set -euo pipefail

test_script="apply_modifier_on_stats"
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
  "${test_script}.sh" ./acor.tsv ./stat.tsv > ./observed-result1.txt

  _check_results ./observed-result1.txt ./expected-result1.tsv

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Case 1

_setup "input P, SE, B, Z, EAF, linear regression"

cat <<EOF > ./acor.tsv
0	A1	A2	CHRPOS	RSID	EffectAllele	OtherAllele	EMOD
1	A	G	12:126406434	rs1000000	G	A	-1
EOF

cat <<EOF > ./stat.tsv
0	B	SE	Z	P	EAF
1	-0.0143	0.0156	-0.916667	0.3604	0.373
EOF

cat <<EOF > ./expected-result1.tsv
0	CHR	POS	RSID	EffectAllele	OtherAllele	P	SE	B	Z	EAF
1	12	126406434	rs1000000	G	A	0.3604	0.0156	0.0143	0.916667	0.627
EOF

_run_script

#---------------------------------------------------------------------------------
# Case 2

_setup "input P, SE, B, Z linear regression"

cat <<EOF > ./acor.tsv
0	A1	A2	CHRPOS	RSID	EffectAllele	OtherAllele	EMOD
1	A	G	12:126406434	rs1000000	G	A	-1
EOF

cat <<EOF > ./stat.tsv
0	B	SE	Z	P
1	-0.0143	0.0156	-0.916667	0.3604
EOF

cat <<EOF > ./expected-result1.tsv
0	CHR	POS	RSID	EffectAllele	OtherAllele	P	SE	B	Z
1	12	126406434	rs1000000	G	A	0.3604	0.0156	0.0143	0.916667
EOF

_run_script

#---------------------------------------------------------------------------------
# Case 3

_setup "input P, SE, OR, INFO logistic regression"

cat <<EOF > ./acor.tsv
0	A1	A2	CHRPOS	RSID	EffectAllele	OtherAllele	EMOD
1	A	G	12:126406434	rs1000000	G	A	-1
EOF

cat <<EOF > ./stat.tsv
0	SE	P	OR	INFO
1	0.0112	0.2696	0.98768	0.99
EOF

cat <<EOF > ./expected-result1.tsv
0	CHR	POS	RSID	EffectAllele	OtherAllele	P	SE	INFO	OR
1	12	126406434	rs1000000	G	A	0.2696	0.0112	0.99	1.01247
EOF

_run_script
