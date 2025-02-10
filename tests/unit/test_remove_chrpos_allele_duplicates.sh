#!/usr/bin/env bash

set -euo pipefail

test_script="remove_chrpos_allele_duplicates"
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
  "${test_script}.sh" ./input.tsv ./observed-unique.tsv ./observed-removed.tsv

  _check_results ./observed-unique.tsv ./expected-unique.tsv
  _check_results ./observed-removed.tsv ./expected-removed.tsv

  echo "- [OK] ${curr_case}"
  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Basic duplicate removal

_setup "Remove duplicates based on CHR:POS:A1:A2"

cat <<EOF > ./input.tsv
0	CHRPOS	RSID	A1	A2
1	1:1000	rs123	A	G
2	1:1000	rs456	A	G
3	1:2000	rs789	T	C
4	2:1000	rs321	A	G
5	2:1000	rs654	A	G
EOF

cat <<EOF > ./expected-unique.tsv
0	CHRPOS	RSID	A1	A2
3	1:2000	rs789	T	C
EOF

cat <<EOF > ./expected-removed.tsv
0	CHRPOS	RSID	A1	A2
1	1:1000	rs123	A	G
2	1:1000	rs456	A	G
4	2:1000	rs321	A	G
5	2:1000	rs654	A	G
EOF

_run_script

#---------------------------------------------------------------------------------
# No duplicates case

_setup "No duplicates present"

cat <<EOF > ./input.tsv
0	CHRPOS	RSID	A1	A2
1	1:1000	rs123	A	G
2	1:2000	rs456	T	C
3	2:1000	rs789	C	T
EOF

cat <<EOF > ./expected-unique.tsv
0	CHRPOS	RSID	A1	A2
1	1:1000	rs123	A	G
2	1:2000	rs456	T	C
3	2:1000	rs789	C	T
EOF

cat <<EOF > ./expected-removed.tsv
0	CHRPOS	RSID	A1	A2
EOF

_run_script

#---------------------------------------------------------------------------------
# Different allele order case

_setup "Different allele order considered unique"

cat <<EOF > ./input.tsv
0	CHRPOS	RSID	A1	A2
1	1:1000	rs123	A	G
2	1:1000	rs456	G	A
3	2:1000	rs789	T	C
EOF

cat <<EOF > ./expected-unique.tsv
0	CHRPOS	RSID	A1	A2
1	1:1000	rs123	A	G
2	1:1000	rs456	G	A
3	2:1000	rs789	T	C
EOF

cat <<EOF > ./expected-removed.tsv
0	CHRPOS	RSID	A1	A2
EOF

_run_script

#---------------------------------------------------------------------------------
# Empty file case

_setup "Empty file (header only)"

cat <<EOF > ./input.tsv
0	CHRPOS	RSID	A1	A2
EOF

cat <<EOF > ./expected-unique.tsv
0	CHRPOS	RSID	A1	A2
EOF

cat <<EOF > ./expected-removed.tsv
0	CHRPOS	RSID	A1	A2
EOF

_run_script 