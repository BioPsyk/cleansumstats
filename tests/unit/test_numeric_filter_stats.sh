#!/usr/bin/env bash

set -euo pipefail

test_script="numeric_filter_stats"
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
  select="${1}"
  returnames="${2}"
  se="${3}"
  skip="${4}"

  "${test_script}.sh" ./input1.tsv "${select}" "${returnames}" "${se}" "${skip}"

  _check_results numeric_filter_stats__st_filtered_remains ./expected-result1.tsv

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# a simple case

_setup "Simple input"

cat <<EOF > ./input1.tsv
0	EFFECT_A1	SE	P	DIRECTION
1	-0.0157	0.0141	0.5770820	+-? 
10	-0.0219	0.0171	0.6963720	--?
100	-0.0321	0.0137	1.7144427	+-?
1000	-0.0189	0.0155	0.6524748	+-?
1001	0.0319	0.0264	0.6449318	+-+
1002	-0.0142	0.0142	0.4981195	+-+
EOF

cat <<EOF > ./expected-result1.tsv
0	EFFECT_A1	SE	P	DIRECTION
1	-0.0157	0.0141	0.5770820	+-? 
10	-0.0219	0.0171	0.6963720	--?
100	-0.0321	0.0137	1.7144427	+-?
1000	-0.0189	0.0155	0.6524748	+-?
1001	0.0319	0.0264	0.6449318	+-+
1002	-0.0142	0.0142	0.4981195	+-+
EOF

_run_script "0|EFFECT_A1|SE|P|DIRECTION" "0,EFFECT_A1,SE,P,DIRECTION" 3 5

#---------------------------------------------------------------------------------
# a case with two columns to skip

_setup "two columns to skip"

cat <<EOF > ./input1.tsv
0	EFFECT_A1	SE	MADEUP	DIRECTION
1	-0.0157	0.0141	***	+-?
10	-0.0219	0.0171	***	--?
100	-0.0321	0.0137	***	+-?
1000	-0.0189	0.0155	***	+-?
1001	0.0319	0.0264	***	+-+
1002	-0.0142	0.0142	***	+-+
EOF

cat <<EOF > ./expected-result1.tsv
0	EFFECT_A1	SE	MADEUP	DIRECTION
1	-0.0157	0.0141	***	+-?
10	-0.0219	0.0171	***	--?
100	-0.0321	0.0137	***	+-?
1000	-0.0189	0.0155	***	+-?
1001	0.0319	0.0264	***	+-+
1002	-0.0142	0.0142	***	+-+
EOF

_run_script "0|EFFECT_A1|SE|MADEUP|DIRECTION" "0,EFFECT_A1,SE,MADEUP,DIRECTION" "3" "4,5"

#---------------------------------------------------------------------------------
# a case with two columns to skip

_setup "NA return"

cat <<EOF > ./input1.tsv
0	chr	pos	ref	alt	af_meta_hq	beta_meta_hq	se_meta_hq	pval_meta_hq
1	1	11063	T	G	4.801e-05	-2.451e-01	2.759e-01	-9.829e-01
10	1	64658	A	T	NA	NA	NA	NA
100	1	736736	A	G	3.749e-02	-3.815e-03	3.096e-03	-1.524e+00
EOF

cat <<EOF > ./expected-result1.tsv
0	beta_meta_hq	se_meta_hq	pval_meta_hq
1	-2.451e-01	2.759e-01	-9.829e-01
100	-3.815e-03	3.096e-03	-1.524e+00
EOF

_run_script "0|beta_meta_hq|se_meta_hq|pval_meta_hq" "0,beta_meta_hq,se_meta_hq,pval_meta_hq" "3" ""
