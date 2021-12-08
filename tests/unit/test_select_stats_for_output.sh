#!/usr/bin/env bash

set -euo pipefail

test_script="select_stats_for_output"
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
  if ! diff -u ${obs} ${exp} &> ./difference; then
    echo "- [FAIL] ${curr_case}"
    cat ./difference
    exit 1
  fi

}

function _run_script {

  "${test_script}.sh" ./input.yaml ./sfile.tsv ./inferred.tsv ./observed-source > ./observed-result1.tsv

  _check_results ./observed-result1.tsv ./expected-result1.tsv
  _check_results ./observed-source ./expected-source

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Reformat_chromosome_information

_setup "Simple test"

cat <<EOF > ./input.yaml
col_BETA: EFFECT_A1
col_P: P
col_POS: BP
col_SE: SE
stats_Model: linear
EOF


cat <<EOF > ./sfile.tsv
0	EFFECT_A1	SE	P	AF_1KG_CS
1	-0.0157	0.0141	0.2648	0.68
10	-0.0219	0.0171	0.2012	NA
100	-0.0321	0.0137	0.0193	NA
1000	-0.0189	0.0155	0.2226	NA
1001	0.0319	0.0264	0.2265	NA
1002	-0.0142	0.0142	0.3176	0.71
1003	-0.0315	0.0277	0.2547	0.93
1004	0.007	0.0175	0.6873	NA
1005	-6e-04	0.015	0.9663	NA
EOF

cat <<EOF > ./inferred.tsv
0	zscore_from_beta_se	zscore_from_pval_beta	zscore_from_pval_beta_N	pval_from_zscore_N	pval_from_zscore
1	-1.113475	-0.000000	nan	-nan	0.791164
10	-1.280702	nan	nan	-nan	0.840542
100	-2.343066	nan	nan	-nan	0.984602
1000	-1.219355	nan	nan	-nan	0.823847
1001	1.208333	nan	nan	-nan	0.820813
1002	-1.000000	nan	nan	-nan	0.750788
1003	-1.137184	nan	nan	-nan	0.798955
1004	0.400000	nan	nan	-nan	0.491894
1005	-0.040000	nan	nan	-nan	0.333894
EOF


cat <<EOF > ./expected-result1.tsv
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

cat <<EOF > ./expected-source
B	original
SE	original
Z	zscore_from_beta_se
P	original
EAF_1KG	AF_1KG_CS
EOF

_run_script

#---------------------------------------------------------------------------------
# Next case


