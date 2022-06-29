#!/usr/bin/env bash

set -euo pipefail

test_script="flip_effects"
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

    echo "obs-----"
    cat ${obs}
    echo "exp-----"
    cat ${exp}
    echo "--------"

    echo "- [FAIL] ${curr_case}"
    cat ./difference 
    exit 1
  fi
}

function _run_script {
  "${test_script}.sh" ./stat.tsv ./acor.tsv > ./observed-result1.txt

  _check_results ./observed-result1.txt ./expected-result1.tsv

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Case 1

_setup "input P, SE, B, Z, EAF, linear regression"

cat <<EOF > ./stat.tsv
0	B	SE	Z	P	EAF
1	-0.0143	0.0156	-0.916667	0.3604	0.373
EOF

cat <<EOF > ./acor.tsv
0	A1	A2	CHRPOS	RSID	EffectAllele	OtherAllele	EMOD
1	A	G	12:126406434	rs1000000	G	A	-1
EOF

cat <<EOF > ./expected-result1.tsv
0	B	SE	Z	P	EAF
1	0.0143	0.0156	0.916667	0.3604	0.627
EOF

_run_script

#---------------------------------------------------------------------------------
# Case 2

_setup "input P, SE, B, Z, EAF, logistic regression"

cat <<EOF > ./stat.tsv
0	OR	SE	Z	P	EAF
1	-0.1143	0.0156	-0.916667	0.3604	0.373
EOF

cat <<EOF > ./acor.tsv
0	A1	A2	CHRPOS	RSID	EffectAllele	OtherAllele	EMOD
1	A	G	12:126406434	rs1000000	G	A	-1
EOF

cat <<EOF > ./expected-result1.tsv
0	OR	SE	Z	P	EAF
1	-8.74891	0.0156	0.916667	0.3604	0.627
EOF

_run_script

#---------------------------------------------------------------------------------
# Case 3

_setup "NA as EAF"

cat <<EOF > ./stat.tsv
0	B	SE	Z	P	EAF
1	-0.0143	0.0156	-0.916667	0.3604	NA
EOF

cat <<EOF > ./acor.tsv
0	A1	A2	CHRPOS	RSID	EffectAllele	OtherAllele	EMOD
1	A	G	12:126406434	rs1000000	G	A	-1
EOF

cat <<EOF > ./expected-result1.tsv
0	B	SE	Z	P	EAF
1	0.0143	0.0156	0.916667	0.3604	NA
EOF

_run_script

#---------------------------------------------------------------------------------
# Case 4 - bugfix-352, zero-division and wrong modification of ORU and ORL

_setup "OR, ORU95 and ORL95"

cat <<EOF > ./stat.tsv
0	SE	P	OR	ORL95	ORU95	CaseN	ControlN	INFO	DIRECTION
10000093	2048	0.9937	10921020.75888	0.00153	0	1062	1062	0.928	???????+??
EOF

cat <<EOF > ./acor.tsv
0	A1	A2	CHRPOS	RSID	EffectAllele	OtherAllele	EMOD
10000093	A	G	12:126406434	rs1000000	G	A	-1
EOF

cat <<EOF > ./expected-result1.tsv
0	SE	P	OR	ORL95	ORU95	CaseN	ControlN	INFO	DIRECTION
10000093	2048	0.9937	9.15665e-08	653.595	0	1062	1062	0.928	???????+??
EOF

_run_script

