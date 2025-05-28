#!/usr/bin/env bash

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
project_dir=$(dirname "${tests_dir}")
schemas_dir="${project_dir}/assets/schemas"
work_dir="${project_dir}/tmp/regression_missing_variants"
outdir="${work_dir}/out"
log_dir="${project_dir}/test_logs"

# Create log directory if it doesn't exist
mkdir -p "${log_dir}"

echo "regression-missing-variants-started"

# Redirect all output to log file
exec > "${log_dir}/regression-missing-variants.log" 2>&1

rm -rf "${work_dir}"
mkdir "${work_dir}"

cd "${work_dir}"

cat <<EOF > ./metadata.yaml
cleansumstats_metafile_kind: library
cleansumstats_metafile_user: webuser
cleansumstats_metafile_date: '2021-10-29'
path_sumStats: input.txt.gz
study_includedCohorts:
  - iPSYCH2012
study_Title: e2e_test
study_PMID: e2e_test_pmid
study_Year: 2020
study_PhenoDesc: Broad depression
path_supplementary: []
study_PhenoCode:
  - EFO:0003761
study_AccessDate: '2021-10-29'
study_Use: restricted
study_Ancestry: EUR, EAS
study_Gender: mixed
stats_Model: linear
stats_TraitType: quantitative
stats_TotalN: 12441
stats_CaseN: 12441
stats_ControlN: 12441
stats_GCMethod: none
stats_neglog10P: false
stats_log10P: false
col_BETA: EFFECT_A1
col_CHR: CHR
col_EffectAllele: A1
col_OtherAllele: A2
col_P: P
col_POS: BP
col_SNP: SNP
col_CaseN: Ncase
col_ControlN: Ncont
col_CaseEAF: CaseAF
EOF

cat <<EOF > ./input.txt
SNP	CHR	BP	A1	A2	EFFECT_A1	P	Ncase	Ncont	CaseAF
chr3:10391:IG	3	10391	C	CT	0.0187	0.001	140	1257	0.9
chr3:10391:SG	3	10391	T	C	0.0187	0.001	140	1257	0.9
EOF

cat <<EOF > ./expected-result1.tsv
CHR	POS	0	RSID	EffectAllele	OtherAllele	B	Z	P	CaseN	ControlN	CaseEAF
3	10391	2	rs1260592493	C	T	-0.0187	-3.290527	0.001	140	1257	0.1
EOF

gzip "./input.txt"

time nextflow -q run -offline \
     -work-dir "${work_dir}" \
     "/cleansumstats" \
     --dev true \
     --input "metadata.yaml" \
     --outdir "${outdir}" \
     --libdirdbsnp "${tests_dir}/example_data/dbsnp/generated_reference_chr3_10391" \
     --libdir1kaf "${tests_dir}/example_data/1kgp/generated_reference"
if [[ $? != 0 ]]
then
  cat .nextflow.log
  echo "regression-missing-variants-failed" > /dev/stderr
  exit 1
fi

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

function _check_results {
  obs=$1
  exp=$2
  if ! diff -u ${obs} ${exp} &> ./difference; then
   echo "----------obs cat -A ---------------"
   cat -A $obs
   echo "----------exp cat -A --------------"
   cat -A $exp
   echo "---------------------------"
   cat ./difference
   echo "regression-missing-variants-failed" > /dev/stderr
   exit 1
  fi
}

mv ${outdir}/cleaned_GRCh38 ./observed-result1.tsv
_check_results ./observed-result1.tsv ./expected-result1.tsv

echo "regression-missing-variants-succeeded" > /dev/stderr

