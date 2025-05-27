#!/usr/bin/env bash

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
project_dir=$(dirname "${tests_dir}")
schemas_dir="${project_dir}/assets/schemas"
work_dir="${project_dir}/tmp/regression-438"
outdir="${work_dir}/out"

rm -rf "${work_dir}"
mkdir "${work_dir}"

echo ">> Test regression #438"

cd "${work_dir}"

cat <<EOF > ./metadata.yaml
cleansumstats_metafile_kind: library
cleansumstats_metafile_user: webuser
cleansumstats_metafile_date: '2021-10-29'
path_sumStats: input.txt.gz
study_includedCohorts:
  - TestCohort
study_Title: Test for -log10 p-value conversion bug
study_PMID: test_438
study_Year: 2023
study_PhenoDesc: Test phenotype for p-value conversion
path_supplementary: []
study_PhenoCode:
  - EFO:0000000
study_AccessDate: '2021-10-29'
study_Use: open
study_Ancestry: EUR
study_Gender: mixed
stats_Model: logistic
stats_TraitType: case-control
stats_TotalN: 26073
stats_GCMethod: none
stats_neglog10P: true
col_CHR: CHROM
col_POS: GENPOS
col_EffectAllele: ALLELE1
col_OtherAllele: ALLELE0
col_SE: SE
col_BETA: BETA
col_P: LOG10P
col_EAF: A1FREQ
col_N: N
col_SNP: ID
EOF

# Create test data with known -log10 p-values and their expected conversions
# Using a subset of the original bug report data with known expected values
cat <<EOF > ./input.txt
CHROM	GENPOS	ID	ALLELE0	ALLELE1	A1FREQ	INFO	N	TEST	BETA	SE	CHISQ	LOG10P	EXTRA
10	7431948	rs55861025	A	C	0.0486831	0.889799	26073	ADD	-0.269422	0.0547078	24.2532	6.07331	NA
12	96068197	rs2660873	T	C	0.264559	0.999535	26073	ADD	0.116767	0.0237869	24.0971	6.0381	NA
14	26966076	rs34902905	AT	A	0.000376018	0.534738	26073	ADD	3.35603	0.678701	24.4509	6.1179	NA
14	27037981	rs531504334	A	C	0.000374439	0.548067	26073	ADD	3.42558	0.677132	25.593	6.37513	NA
14	27056327	rs550802601	C	T	0.000374138	0.54826	26073	ADD	3.4213	0.677003	25.5389	6.36296	NA
EOF

# Expected results with correct p-value conversions
# -log10(p) = 6.07331 -> p = 8.446757e-07
# -log10(p) = 6.0381  -> p = 9.160095e-07  
# -log10(p) = 6.1179  -> p = 7.622545e-07
# -log10(p) = 6.37513 -> p = 4.215703e-07
# -log10(p) = 6.36296 -> p = 4.335508e-07
cat <<EOF > ./expected-result1.tsv
CHR	POS	0	RSID	EffectAllele	OtherAllele	B	SE	Z	P	N	EAF	EAF_1KG
10	7431948	1	rs55861025	C	A	0.269422	0.0547078	4.923	8.446757e-07	26073	0.951317	0.95
12	96068197	2	rs2660873	C	T	0.116767	0.0237869	4.908	9.160095e-07	26073	0.735441	0.74
14	26966076	3	rs34902905	A	AT	-3.35603	0.678701	-4.946	7.622545e-07	26073	0.999624	1.00
14	27037981	4	rs531504334	C	A	0.374439	0.677132	5.059	4.215703e-07	26073	0.999626	1.00
14	27056327	5	rs550802601	T	C	-3.4213	0.677003	-5.054	4.335508e-07	26073	0.999626	1.00
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

    echo "- [FAIL] regression-438: P-value conversion from -log10 scale produces incorrect values"
    echo "Expected p-values should be:"
    echo "  -log10(p) = 6.07331 -> p = 8.446757e-07"
    echo "  -log10(p) = 6.0381  -> p = 9.160095e-07"
    echo "  -log10(p) = 6.1179  -> p = 7.622545e-07"
    echo "  -log10(p) = 6.37513 -> p = 4.215703e-07"
    echo "  -log10(p) = 6.36296 -> p = 4.335508e-07"
    echo ""
    echo "Differences found:"
    cat ./difference
    exit 1
  fi

}

mv ${outdir}/cleaned_GRCh38 ./observed-result1.tsv
_check_results ./observed-result1.tsv ./expected-result1.tsv

echo "- [PASS] regression-438" 