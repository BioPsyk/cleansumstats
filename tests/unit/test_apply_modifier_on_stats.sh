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
  header=$(head -n 1 ./result.tsv)

  IFS=$'\t' read -r -a columns <<< "${header}"
  unset IFS

  expected_columns=(
    "0" "CHR" "POS" "RSID" "EffectAllele" "OtherAllele"
    "P" "SE" "B" "Z"
  )

  for exp in "${expected_columns[@]}"
  do
    if [[ ! " ${columns[@]} " =~ " ${exp} " ]]; then
      echo "- [FAIL] ${curr_case}: Column '${exp}' was missing from expected columns:"
      echo "  '${expected_columns[@]}'"
      exit 1
    fi
  done

  echo "- [OK] ${curr_case}"
}

function _run_script {
  "${test_script}.sh" ./acor.tsv ./stat.tsv > ./result.tsv

  _check_results

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Using valid rows that contains all columns

_setup "valid_rows_all_columns"

cat <<EOF > ./acor.tsv
0	A1	A2	CHRPOS	RSID	EffectAllele	OtherAllele	EMOD
1	A	G	12:126406434	rs1000000	G	A	-1
EOF

cat <<EOF > ./stat.tsv
0	B	SE	Z	P	AFREQ
1	-0.0143	0.0156	-0.916667	0.3604	0.373
EOF

_run_script

#---------------------------------------------------------------------------------
# Using valid rows that is missing the AFREQ column

_setup "valid_rows_missing_afreq"

cat <<EOF > ./acor.tsv
0	A1	A2	CHRPOS	RSID	EffectAllele	OtherAllele	EMOD
1	A	G	12:126406434	rs1000000	G	A	-1
EOF

cat <<EOF > ./stat.tsv
0	B	SE	Z	P
1	-0.0143	0.0156	-0.916667	0.3604
EOF

_run_script
