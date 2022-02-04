#!/usr/bin/env bash

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
project_dir=$(dirname "${tests_dir}")
schemas_dir="${project_dir}/assets/schemas"
work_dir="${project_dir}/tmp/regression-257"
outdir="${work_dir}/out"

rm -rf "${work_dir}"
mkdir "${work_dir}"

echo ">> Test regression #257"

cd "${work_dir}"

cat <<EOF > ./metadata.yaml
cleansumstats_metafile_date: '2020-12-31'
cleansumstats_metafile_user: username
cleansumstats_version: 1.0.0-alpha
path_sumStats: input.txt.gz
col_CHR: CHR
col_SNP: SNP
col_POS: BP
col_EffectAllele: A1
col_OtherAllele: A2
col_INFO: INFO
col_OR: OR
col_SE: SE
col_P: P
col_Direction: Direction
stats_TotalN: 1
stats_GCMethod: none
stats_Model: logistic
stats_Notes: 'dummy description'
stats_TraitType: quantitative
stats_neglog10P: false
study_AccessDate: '2020-12-31'
study_Ancestry: EUR
study_Array: meta
study_FilePortal: http://website.org/dummydata
study_FileURL: http://website.org/dummydata/file.txt.gz
study_Gender: mixed
study_ImputePanel: HapMap
study_ImputeSoftware: meta
study_PMID: 666
study_PhasePanel: meta
study_PhaseSoftware: meta
study_PhenoCode:
- EFO:0000000
study_PhenoDesc: 'phenotype description'
study_Title: dummy_title
study_Use: open
study_Year: 2020
EOF

cat <<EOF | gzip -c > ./input.txt.gz
CHR	SNP	BP	A1	A2	FRQ_A_20352	FRQ_U_31358	INFO	OR	SE	P	ngt	Direction	HetISqt	HetChiSq	HetDf	HetPVa
3	rs6439928	141663261	T	C	0.00935	0.0081	0.67	1.16813	0.0923	0.09239	0	+--+++++--+?++--+-+-?++++++++--+	0.0	26.296	29	0.6096
3	rs6443624	180380376	A	G	0.0049	0.0051	0.948	0.96580	0.8946	0.969	0	????????-???????????????????????	0.0	0.000	0	1
3	rs6444089	187159052	A	G	0.661	0.657	0.955	1.00743	0.0144	0.607	0	--++----++++-++---++-++++-+-+++-	0.0	28.264	31	0.6075
11	rs645184	73806781	I2	D	0.97	0.97	0.932	0.99203	0.0405	0.8445	0	--++-+++-++-++-++---+--+-+---+--	0.0	22.994	31	0.8494
12	rs645510	116569153	A	G	0.313	0.311	0.954	0.99960	0.0147	0.9787	0	--++++-++--+-+--++-------++-+-++	0.0	16.036	31	0.9878
6	rs6456063	166624019	T	G	0.985	0.985	0.862	0.98442	0.0598	0.7923	0	---+++--+++-++-++----+----++---+	-4.9	31.465	31	0.443
6	rs6458154	40461984	A	C	0.0146	0.0145	0.668	1.08210	0.0686	0.2502	0	++++---+?-+--+-+-++++++--++-+--+	0.0	21.421	30	0.8743
EOF

cat <<EOF > ./expected-result1.tsv
CHR	POS	0	RSID	EffectAllele	OtherAllele	P	SE	INFO	Direction	B	Z	EAF_1KG	OR
12	117668628	5	rs645510	C	T	0.9787	0.0147	0.954	--++++-++--+-+--++-------++-+-++	0.0004	0.026699	0.67	1.0004
3	140461721	1	rs6439928	T	C	0.09239	0.0923	0.67	+--+++++--+?++--+-+-?++++++++--+	0.155404	1.68292	0.68	1.16813
EOF

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

    echo "- [FAIL] regression-257"
    cat ./difference
    exit 1
  fi

}

mv ${outdir}/cleaned_GRCh38 ./observed-result1.tsv
_check_results ./observed-result1.tsv ./expected-result1.tsv
