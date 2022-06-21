#!/usr/bin/env bash

set -euo pipefail

test_script="check_stat_inference_avail"
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

  branchX=$1

  "${test_script}.sh" ./colfields.txt ./colnames.txt ./colpositions.txt "${branchX}" ./infile.tsv

  _check_results ./colfields.txt ./expected-colfields.txt
  _check_results ./colnames.txt ./expected-colnames.txt
  _check_results ./colpositions.txt ./expected-colpositions.txt

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Case 1

_setup "input P, SE, OR, logistic regression"

cat <<EOF > ./infile.tsv
0	P	SE	OR
1	0.001	0.2	0.3
EOF

cat <<EOF > ./expected-colfields.txt
0|SE|P|OR
EOF

cat <<EOF > ./expected-colpositions.txt
--index 1 --standarderror 2 --pvalue 3 --oddsratio 4
EOF

cat <<EOF > ./expected-colnames.txt
0,SE,P,OR
EOF


_run_script "branchX"

#---------------------------------------------------------------------------------
# Case 2 - hotfix-245 - the last entry of available stat types was previously missed
#                       That last entry was "allelefreq"

_setup "input P, SE, OR, AF(1KGP) linear regression"

cat <<EOF > ./infile.tsv
0	P	SE	OR	AF_1KG_CS
1	0.001	0.2	0.3	0.33
EOF

cat <<EOF > ./expected-colfields.txt
0|SE|P|OR|AF_1KG_CS
EOF

cat <<EOF > ./expected-colpositions.txt
--index 1 --standarderror 2 --pvalue 3 --oddsratio 4 --allelefreq 5
EOF

cat <<EOF > ./expected-colnames.txt
0,SE,P,OR,AF_1KG_CS
EOF

_run_script "g1kaf_stats_branch"
