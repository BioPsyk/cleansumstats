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

#---------------------------------------------------------------------------------
# Case 4 - Major bug for EAF_1KG #289, NA's turn to 1's

_setup "input P, SE, OR, INFO logistic regression"

cat <<EOF > ./acor.tsv
0	A1	A2	CHRPOS	RSID	EffectAllele	OtherAllele	EMOD
1	T	C	3:140461721	rs6439928	T	C	1
10	T	C	7:43168054	rs6463169	C	T	-1
1000	A	G	2:28958241	rs10197378	G	A	-1
1002	A	G	18:31901577	rs12709653	A	G	1
1003	A	G	1:154199074	rs12726220	A	G	1
1005	T	C	1:8413753	rs12754538	C	T	-1
1008	T	C	10:118368257	rs12767500	C	T	-1
101	A	G	4:10060702	rs6834555	G	A	-1
1010	T	C	10:36429198	rs12771570	C	T	-1
EOF

cat <<EOF > ./stat.tsv
0	B	SE	Z	P	EAF_1KG
1	-0.0157	0.0141	-1.113475	0.2648	0.68
10	-0.0219	0.0171	-1.280702	0.2012	NA
100	-0.0321	0.0137	-2.343066	0.0193	NA
1000	-0.0189	0.0155	-1.219355	0.2226	NA
1001	0.0319	0.0264	1.208333	0.2265	NA
1002	-0.0142	0.0142	-1.000000	0.3176	0.71
1003	-0.0315	0.0277	-1.137184	0.2547	0.93
1004	0.007	0.0175	0.400000	0.6873	NA
1005	-6e-04	0.015	-0.040000	0.9663	NA
EOF

cat <<EOF > ./expected-result1.tsv
0	CHR	POS	RSID	EffectAllele	OtherAllele	P	SE	B	Z	EAF_1KG
1	3	140461721	rs6439928	T	C	0.2648	0.0141	-0.0157	-1.11347	0.68
10	7	43168054	rs6463169	C	T	0.2012	0.0171	0.0219	1.2807	NA
1000	2	28958241	rs10197378	G	A	0.2226	0.0155	0.0189	1.21935	NA
1002	18	31901577	rs12709653	A	G	0.3176	0.0142	-0.0142	-1	0.71
1003	1	154199074	rs12726220	A	G	0.2547	0.0277	-0.0315	-1.13718	0.93
1005	1	8413753	rs12754538	C	T	0.9663	0.015	0.0006	0.04	NA
EOF

_run_script
