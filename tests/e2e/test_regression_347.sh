#!/usr/bin/env bash

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
project_dir=$(dirname "${tests_dir}")
schemas_dir="${project_dir}/assets/schemas"
work_dir="${project_dir}/tmp/regression-347"
outdir="${work_dir}/out"

rm -rf "${work_dir}"
mkdir "${work_dir}"

echo ">> Test regression #347"

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
col_OtherAllele: A2
col_P: P
col_POS: BP
col_SE: SE
col_SNP: SNP
col_EAF: eurAF
EOF

#The problem
#The added 1KG allele frequencies are not flipped when needed

#Manually added real eurAF from 1000G. The idea is that the EAF_1KGP column should contain the same after cleaning.
#And as can be seen, it corresponds well with the original sumstats FREQ_A1
cat <<EOF > ./input.txt
SNP	CHR	BP	A1	A2	FREQ_A1	EFFECT_A1	SE	P	eurAF
rs12709653	chr18	27735538	A	G	0.775	-0.0142	0.49811951	0.3176	0.7167
rs12726220	chr1	150984623	A	G	0.948	-0.0315	0.59397106	0.2547	0.9274
rs12754538	chr1	8408079	T	C	0.308	-6e-04	0.015	0.01488802	0.7913
rs10197378	chr2	29092758	A	G	0.183	-0.0189	0.65247484	0.2226	0.2068
rs6439928	chr3	141663261	T	C	0.658	-0.0157	0.57708202	0.2648	0.6869
rs6463169	chr7	42980893	T	C	0.825	-0.0219	0.69637202	0.2012	0.7913
EOF

#rs12754538 has flipped effect allele from T to C
#rs10197378 has flipped effect allele from A to G
#rs6463169 has flipped effect allele from T to C
#NOTE: this is a sumstat with -neglog10=true, so P values are not same as input.
cat <<EOF > ./expected-result1.tsv
CHR	POS	0	RSID	EffectAllele	OtherAllele	P	SE	B	Z	EAF	EAF_1KG
18	31901577	1	rs12709653	A	G	0.481282	0.49811951	-0.0142	-0.028507	0.7167	0.71
1	154199074	2	rs12726220	A	G	0.556288	0.59397106	-0.0315	-0.053033	0.9274	0.93
1	8413753	3	rs12754538	C	T	0.966300	0.015	0.0006	0.04	0.2087	0.22
2	28958241	4	rs10197378	G	A	0.598963	0.65247484	0.0189	0.028967	0.7932	0.79
3	140461721	5	rs6439928	T	C	0.543501	0.57708202	-0.0157	-0.027206	0.6869	0.68
7	43168054	6	rs6463169	C	T	0.629216	0.69637202	0.0219	0.031449	0.2087	0.21
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
   echo "obs------------------------"
   cat $obs
   echo "exp------------------------"
   cat $exp
   echo "---------------------------"

    echo "- [FAIL] regression-347"
    cat ./difference
    exit 1
  fi

}

mv ${outdir}/cleaned_GRCh38 ./observed-result1.tsv
_check_results ./observed-result1.tsv ./expected-result1.tsv
