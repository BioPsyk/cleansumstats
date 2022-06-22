#!/usr/bin/env bash

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
project_dir=$(dirname "${tests_dir}")
schemas_dir="${project_dir}/assets/schemas"
work_dir="${project_dir}/tmp/regression-242"
outdir="${work_dir}/out"

rm -rf "${work_dir}"
mkdir "${work_dir}"

echo ">> Test regression #242"

cd "${work_dir}"

cat <<EOF > ./metadata.yaml
cleansumstats_metafile_kind: library
cleansumstats_metafile_user: webuser
cleansumstats_metafile_date: '2021-10-29'
path_sumStats: input.txt.gz
study_includedCohorts:
  - iPSYCH2012
study_Title: Inhouse GWAS iPSYCH2012 F3300
study_PMID: iPSYCH2012_F3300
study_Year: 2020
study_PhenoDesc: Broad depression
path_supplementary: []
study_PhenoCode:
  - EFO:0003761
study_AccessDate: '2021-10-29'
study_Use: restricted
study_Ancestry: EUR
study_Gender: mixed
stats_Model: linear
stats_TraitType: quantitative
stats_TotalN: 12441
stats_GCMethod: none
stats_neglog10P: true
col_BETA: EFFECT_A1
col_CHR: CHR
col_EffectAllele: A1
col_P: P
col_POS: BP
col_SE: SE
col_SNP: SNP
EOF

cat <<EOF > ./input.txt
SNP CHR BP A1 A2 FREQ_A1 EFFECT_A1 SE P
rs6439928	chr3	141663261	T	C	0.658	-0.0157	0.0141	0.2648
rs6443624	chr3	180380376	A	C	0.242	0.0027	0.0155	0.8603
rs6444089	chr3	187159052	A	G	0.55	0.0043	0.0128	0.7394
rs645184	chr11	73806781	A	G	0.608	0.003	0.0129	0.8169
rs645510	chr12	116569153	T	C	0.675	-0.0151	0.0143	0.292
rs6456063	chr6	166624019	A	G	0.783	0.0245	0.018	0.1735
rs6458154	chr6	40461984	A	G	0.458	0.0126	0.0132	0.3407
EOF

cat <<EOF > ./expected-result1.tsv
CHR	POS	0	RSID	EffectAllele	OtherAllele	B	SE	Z	P	EAF_1KG
12	117668628	5	rs645510	C	T	0.0151	0.0143	1.055944	0.510505	0.33
3	140461721	1	rs6439928	T	C	-0.0157	0.0141	-1.113475	0.543501	0.68
EOF

gzip "./input.txt"

time nextflow -q run -offline \
     -work-dir "${work_dir}" \
     "/cleansumstats" \
     --dev true \
     --input "metadata.yaml" \
     --outdir "${outdir}" \
     --libdirdbsnp "${tests_dir}/example_data/dbsnp/generated_reference" \
     --libdir1kaf "${tests_dir}/example_data/1kgp/generated_reference"
if [[ $? != 0 ]]
then
  cat .nextflow.log
  exit 1
fi

echo "-- Pipeline done, general validation"

for f in ./out/cleaned_metadata.yaml
do
  "${tests_dir}/validators/validate-cleaned-metadata.py" \
    "${schemas_dir}/cleaned-metadata.yaml" "${f}"
done

for f in ./out/*.gz
do
  gzip --decompress "${f}"
  "${tests_dir}/validators/validate-cleaned-sumstats.py" \
    "${schemas_dir}/cleaned-sumstats.yaml" "${f%.gz}"
done

echo "-- Pipeline done, specific validation"

function _check_results {
  obs=$1
  exp=$2
  if ! diff -u ${obs} ${exp} &> ./difference; then
   echo "----------obs---------------"
   cat $obs
   echo "----------exp--------------"
   cat $exp
   echo "---------------------------"

    echo "- [FAIL] regression-242"
    cat ./difference
    exit 1
  fi

}

mv ${outdir}/cleaned_GRCh38 ./observed-result1.tsv
_check_results ./observed-result1.tsv ./expected-result1.tsv
