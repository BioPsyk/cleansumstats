#!/usr/bin/env bash

set -euo pipefail

test_script="create_output_meta_data_file_cleaned"
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

  "${test_script}.sh" ./mfile_additions ./header.tsv > ./observed-result1.tsv

  _check_results ./observed-result1.tsv ./expected-result1.tsv

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# cleaned metadata addtions 

_setup "Simple test"

cat <<EOF > ./mfile_additions
cleansumstats_version: 1.6.6
cleansumstats_date: 2023-11-22-1538
cleansumstats_user: jesgaaopen
cleansumstats_cleaned_GRCh38: sumstat_cleaned_GRCh38.gz
cleansumstats_cleaned_GRCh38_checksum: ff0d294b2b9329b0ac1fab56011a99dd94ccd83169cd340562b2aba85a709728
cleansumstats_cleaned_GRCh37_coordinates: sumstat_cleaned_GRCh37.gz
cleansumstats_cleaned_GRCh37_coordinates_checksum: 0472bdefc664f7e09f10241d8d9cef05724ee62131921c27ff359acec7fe436a
cleansumstats_removed_lines: sumstat_removed_lines.gz
cleansumstats_removed_lines_checksum: 9a313ac7e526687e3d6c95946bf40a52e7eff855303d585e899a594ebeb4dcb0
cleansumstats_metafile_user_checksum: a041156ea425da461b5f448abe525bcee19be8090efb66438bcce9b205924769
cleansumstats_sumstat_raw_checksum: b8eda3314bf85535db5924bf75cf49ec569985c6f674aabad9cb07454d13a31d
stats_EffectiveN: 78308
EOF

cat <<EOF > ./header.tsv
CHR	POS	0	RSID	EffectAllele	OtherAllele	B	SE	Z	P	N	EAF_1KG	Direction
EOF


cat <<EOF > ./expected-result1.tsv
cleansumstats_version: 1.6.6
cleansumstats_date: 2023-11-22-1538
cleansumstats_user: jesgaaopen
cleansumstats_cleaned_GRCh38: sumstat_cleaned_GRCh38.gz
cleansumstats_cleaned_GRCh38_checksum: ff0d294b2b9329b0ac1fab56011a99dd94ccd83169cd340562b2aba85a709728
cleansumstats_cleaned_GRCh37_coordinates: sumstat_cleaned_GRCh37.gz
cleansumstats_cleaned_GRCh37_coordinates_checksum: 0472bdefc664f7e09f10241d8d9cef05724ee62131921c27ff359acec7fe436a
cleansumstats_removed_lines: sumstat_removed_lines.gz
cleansumstats_removed_lines_checksum: 9a313ac7e526687e3d6c95946bf40a52e7eff855303d585e899a594ebeb4dcb0
cleansumstats_metafile_user_checksum: a041156ea425da461b5f448abe525bcee19be8090efb66438bcce9b205924769
cleansumstats_sumstat_raw_checksum: b8eda3314bf85535db5924bf75cf49ec569985c6f674aabad9cb07454d13a31d
stats_EffectiveN: 78308
cleansumstats_col_RAWROWINDEX: 0
cleansumstats_col_CHR: CHR
cleansumstats_col_POS: POS
cleansumstats_col_SNP: RSID
cleansumstats_col_EffectAllele: EffectAllele
cleansumstats_col_OtherAllele: OtherAllele
cleansumstats_col_BETA: B
cleansumstats_col_SE: SE
cleansumstats_col_Z: Z
cleansumstats_col_P: P
cleansumstats_col_N: N
cleansumstats_col_Direction: Direction
cleansumstats_col_Notes: If possible, missing stats have been calculated from the avialable. If OtherAllele was missing we use the alternate allele according to the dbsnp reference
EOF

_run_script

#---------------------------------------------------------------------------------
# Next case


