#!/usr/bin/env bash

set -euo pipefail

test_script="map_to_adhoc_function"
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
  coltype=${1}

  "${test_script}.sh" ${ch_regexp_lexicon} ./input.yaml ./input.tsv "${coltype}" >  ./observed-result1.tsv

  _check_results ./observed-result1.tsv ./expected-result1.tsv

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Reformat_chromosome_information

_setup "simple input"

cat <<EOF > ./input.yaml
col_CHR: CHR
col_EffectAllele: A1
col_OtherAllele: A2
col_POS: BP
col_SNP: SNP
EOF

cat <<EOF > ./input.tsv
0	SNP	CHR	BP	A1	A2	FREQ_A1	EFFECT_A1	SE	P
1	rs6439928	chr3	141663261	T	C	0.658	-0.0157	0.0141	0.2648
10	rs6463169	chr7	42980893	T	C	0.825	-0.0219	0.0171	0.2012
100	rs6831643	chr4	99833465	T	C	0.669	-0.0321	0.0137	0.0193
1000	rs10197378	chr2	29092758	A	G	0.183	-0.0189	0.0155	0.2226
1001	rs10021082	chr4	100801356	T	C	0.958	0.0319	0.0264	0.2265
1002	rs12709653	chr18	27735538	A	G	0.775	-0.0142	0.0142	0.3176
1003	rs12726220	chr1	150984623	A	G	0.948	-0.0315	0.0277	0.2547
1004	rs12739293	chr1	118812591	T	C	0.133	0.007	0.0175	0.6873
1005	rs12754538	chr1	8408079	T	C	0.308	-6e-04	0.015	0.9663
EOF

cat <<EOF > ./expected-result1.tsv
funx_chrCHR_2_CHR(CHR)
EOF

_run_script "chr"

#---------------------------------------------------------------------------------
# Reformat_chromosome_information using mixed markername info

_setup "mixed chr rs IDs in markername, chrXX"


cat <<EOF > ./input.yaml
col_CHR: CHR
col_EffectAllele: A1
col_OtherAllele: A2
col_POS: BP
col_SNP: SNP
EOF

cat <<EOF > ./input.tsv
0	SNP	CHR	BP	A1	A2	FREQ_A1	EFFECT_A1	SE	P
1	rs6439928	chr3	141663261	T	C	0.658	-0.0157	0.0141	0.2648
1001	rs10021082	chr4	100801356	T	C	0.958	0.0319	0.0264	0.2265
1002	chr18:27735538	chr18	27735538	A	G	0.775	-0.0142	0.0142	0.3176
1003	rs12726220	chr1	150984623	A	G	0.948	-0.0315	0.0277	0.2547
1005	rs12754538	chr1	8408079	T	C	0.308	-6e-04	0.015	0.9663
EOF

cat <<EOF > ./expected-result1.tsv
funx_chrCHR_2_CHR(CHR)
EOF

_run_script "chr"

#---------------------------------------------------------------------------------
# Reformat_chromosome_information using mixed markername info

_setup "mixed chr rs IDs in markername only integers"


cat <<EOF > ./input.yaml
col_CHR: CHR
col_EffectAllele: A1
col_OtherAllele: A2
col_POS: BP
col_SNP: SNP
EOF

cat <<EOF > ./input.tsv
0	SNP	CHR	BP	A1	A2	FREQ_A1	EFFECT_A1	SE	P
1	rs6439928	chr3	141663261	T	C	0.658	-0.0157	0.0141	0.2648
1001	rs10021082	chr4	100801356	T	C	0.958	0.0319	0.0264	0.2265
1002	18:27735538	chr18	27735538	A	G	0.775	-0.0142	0.0142	0.3176
1003	rs12726220	chr1	150984623	A	G	0.948	-0.0315	0.0277	0.2547
1005	rs12754538	chr1	8408079	T	C	0.308	-6e-04	0.015	0.9663
EOF

cat <<EOF > ./expected-result1.tsv
funx_chrCHR_2_CHR(CHR)
EOF

_run_script "chr"
