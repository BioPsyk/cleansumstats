#!/usr/bin/env bash

set -euo pipefail

test_script="allele_correction"
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
  col_A1=$1
  col_A2=$2

  "${test_script}.sh" ./input1.tsv ./input2.tsv ${col_A1} ${col_A2} ./observed-result1.tsv ./observed-result2.tsv

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
# Allele correction - case 1

_setup "Simple input, no filtering"

cat <<EOF > ./input1.tsv
0	SNP	CHR	BP	A1	A2	FREQ_A1	EFFECT_A1	SE	P
1	rs6439928	chr3	141663261	T	C	0.658	-0.0157	0.0141	0.2648
10	rs6463169	chr7	42980893	T	C	0.825	-0.0219	0.0171	0.2012
1000	rs10197378	chr2	29092758	A	G	0.183	-0.0189	0.0155	0.2226
1002	rs12709653	chr18	27735538	A	G	0.775	-0.0142	0.0142	0.3176
1003	rs12726220	chr1	150984623	A	G	0.948	-0.0315	0.0277	0.2547
1005	rs12754538	chr1	8408079	T	C	0.308	-6e-04	0.015	0.9663
EOF

cat <<EOF > ./input2.tsv
0	CHRPOS	RSID	A1	A2
1	3:140461721	rs6439928	T	C
10	7:43168054	rs6463169	C	T
1000	2:28958241	rs10197378	G	A
1002	18:31901577	rs12709653	A	G
1003	1:154199074	rs12726220	A	G
1005	1:8413753	rs12754538	C	T
EOF

cat <<EOF > ./expected-result1.tsv
0	A1	A2	CHRPOS	RSID	EffectAllele	OtherAllele	EMOD
1	T	C	3:140461721	rs6439928	T	C	1
10	T	C	7:43168054	rs6463169	C	T	-1
1000	A	G	2:28958241	rs10197378	G	A	-1
1002	A	G	18:31901577	rs12709653	A	G	1
1003	A	G	1:154199074	rs12726220	A	G	1
1005	T	C	1:8413753	rs12754538	C	T	-1
EOF

cat <<EOF > ./expected-result2.tsv
EOF

_run_script "A1" "A2"

#---------------------------------------------------------------------------------
# Allele correction - case 2

_setup "non GTCA filtering"

cat <<EOF > ./input1.tsv
0	CHR	BP	A1	A2
1	chr3	141663261	T	Y
10	chr7	42980893	T	C
EOF

cat <<EOF > ./input2.tsv
0	CHRPOS	RSID	A1	A2
1	3:140461721	rs6439928	T	C
10	7:43168054	rs6463169	C	T
EOF

cat <<EOF > ./expected-result1.tsv
0	A1	A2	CHRPOS	RSID	EffectAllele	OtherAllele	EMOD
10	T	C	7:43168054	rs6463169	C	T	-1
EOF

cat <<EOF > ./expected-result2.tsv
1	notGCTA
EOF

_run_script "A1" "A2"

#---------------------------------------------------------------------------------
# Allele correction - a lot of filtering cases to test when you get an opportunity write the tests
