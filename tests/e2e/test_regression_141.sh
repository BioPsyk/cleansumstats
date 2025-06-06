#!/usr/bin/env bash

# Check that output from running the whole pipleiine looks as expected
# Specificcaly the order of all columns are right, so there has not
# been an unintentional shuffling of labels
# see issue-141

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
project_dir=$(dirname "${tests_dir}")
schemas_dir="${project_dir}/assets/schemas"
work_dir="${project_dir}/tmp/regression-141"
outdir="${work_dir}/out"

rm -rf "${work_dir}"
mkdir "${work_dir}"

echo ">> Test regression #141"

cd "${work_dir}"

cat <<EOF > ./metadata.yaml
cleansumstats_metafile_date: '2020-04-27'
cleansumstats_metafile_user: Andrew Schork
cleansumstats_metafile_kind: library
col_BETA: EFFECT_A1
col_CHR: CHR
col_EffectAllele: A1
col_OtherAllele: A2
col_P: P
stats_neglog10P: false
col_POS: BP
col_SE: SE
col_SNP: SNP
path_sumStats: input.txt.gz
stats_GCMethod: none
stats_Model: linear
stats_Notes: Discovery sample only, I think. This sumstat_ID was used to test meta
  file update functionality.
stats_TotalN: 12441
stats_TraitType: quantitative
study_AccessDate: '2020-04-27'
study_Ancestry: EUR
study_Array: meta
study_FilePortal: http://ssgac.org/data
study_FileURL: http://ssgac.org/documents/CHIC_Summary_Benyamin2014.txt.gz
study_Gender: mixed
study_ImputePanel: HapMap
study_ImputeSoftware: meta
study_PMID: 23358156
study_PhasePanel: meta
study_PhaseSoftware: meta
study_PhenoCode:
- EFO:0000000
study_PhenoDesc: 'Childhood Intelligence (old phenocode: Childhood IQ)'
study_Title: sumstat_1
study_Use: open
study_Year: 2014
EOF

cat <<EOF > ./input.txt
SNP	CHR	BP	A1	A2	FREQ_A1	EFFECT_A1	SE	P
rs6439928	chr3	141663261	T	C	0.658	-0.0157	0.0141	0.2648
rs6463169	chr7	42980893	T	C	0.825	-0.0219	0.0171	0.2012
rs10197378	chr2	29092758	A	G	0.183	-0.0189	0.0155	0.2226
rs12709653	chr18	27735538	A	G	0.775	-0.0142	0.0142	0.3176
rs12726220	chr1	150984623	A	G	0.948	-0.0315	0.0277	0.2547
rs12754538	chr1	8408079	T	C	0.308	-6e-04	0.015	0.9663
EOF

cat <<EOF > ./expected-result1.tsv
CHR	POS	0	RSID	EffectAllele	OtherAllele	B	SE	Z	P	EAF_1KG
18	31901577	4	rs12709653	A	G	-0.0142	0.0142	-1.000000	0.3176	0.71
1	154199074	5	rs12726220	A	G	-0.0315	0.0277	-1.137184	0.2547	0.93
1	8413753	6	rs12754538	C	T	0.0006	0.015	0.040000	0.9663	0.78
2	28958241	3	rs10197378	G	A	0.0189	0.0155	1.219355	0.2226	0.79
3	140461721	1	rs6439928	T	C	-0.0157	0.0141	-1.113475	0.2648	0.68
7	43168054	2	rs6463169	C	T	0.0219	0.0171	1.280702	0.2012	0.21
EOF

gzip "./input.txt"

time nextflow -q run -offline \
         -c "/cleansumstats/conf/test.config" \
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

    echo "- [FAIL] regression-141"
    cat ./difference
    exit 1
  fi

}

mv ${outdir}/cleaned_GRCh38 ./observed-result1.tsv
_check_results ./observed-result1.tsv ./expected-result1.tsv
