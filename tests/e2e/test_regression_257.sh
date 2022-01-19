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
cleansumstats_metafile_date: '2020-04-28'
cleansumstats_metafile_user: Andrew Schork
cleansumstats_version: 1.3.0
col_CHR: hg19chrc
col_EffectAllele: a1
col_INFO: info
col_OR: or
col_OtherAllele: a2
col_P: p
col_POS: bp
col_SE: se
col_SNP: snpid
path_sumStats: input.txt.gz
stats_CaseN: 36989
stats_ControlN: 113075
stats_GCMethod: none
stats_Model: logistic
stats_TotalN: 150064
stats_TraitType: case-control
stats_neglog10P: false
study_AccessDate: '2020-04-28'
study_Ancestry: EUR
study_Array: meta
study_FilePortal: https://www.med.unc.edu/pgc/download-results/scz/
study_Gender: mixed
study_ImputePanel: 1KGP
study_ImputeSoftware: meta
study_Notes: PGC SCZ2
study_PMID: 25056061
study_PhasePanel: meta
study_PhaseSoftware: meta
study_PhenoCode:
- EFO:0000000
study_PhenoDesc: 'Schizophrenia (old phenocode: Schizophrenia)'
study_Title: sumstat_2
study_Use: open
study_Year: 2014
EOF

cat <<EOF > ./input.txt
hg19chrc	snpid	a1	a2	bp	info	or	se	p	ngt
chr2	rs7594872	A	C	85674576	0.99	0.98768	0.0112	0.2696	26
chr2	rs7585722	T	C	86819128	0.992	1.0014	0.015	0.9273	4
chr2	rs6709175	T	C	87108211	0.995	1.01349	0.0143	0.347	50
chr2	rs2919876	T	C	88381353	0.987	0.99392	0.0149	0.6794	16
chr2	rs6724281	T	G	88529531	0.998	1.00652	0.0116	0.5755	14
chr2	rs810057	T	C	97015073	0.994	1.03376	0.0111	0.002841	26
chr2	rs6875	A	G	98372980	0.995	0.99432	0.0121	0.6354	46
chr2	rs3769689	A	G	99293697	0.997	0.997	0.0118	0.7991	18
chr2	rs12477450	A	C	99340684	1	0.98649	0.0134	0.3121	13
EOF

cat <<EOF > ./expected-result1.tsv
CHR	POS	0	RSID	EffectAllele	OtherAllele	P	SE	INFO	B	Z	EAF_1KG	OR
2	86592005	2	rs7585722	T	C	0.9273	0.015	0.992	0.001399	0.091242	0.86	1.0014
2	86881088	3	rs6709175	T	C	0.347	0.0143	0.995	0.0134	0.940424	0.83	1.01349
2	88081834	4	rs2919876	C	T	0.6794	0.0149	0.987	0.006099	0.413282	1	1.00612
2	88230012	5	rs6724281	T	G	0.5755	0.0116	0.998	0.006499	0.55997	0.28	1.00652
2	98677234	8	rs3769689	A	G	0.7991	0.0118	0.997	-0.003005	-0.254512	0.7	0.997
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

    echo "- [FAIL] regression-257"
    cat ./difference
    exit 1
  fi

}

mv ${outdir}/cleaned_GRCh38 ./observed-result1.tsv
_check_results ./observed-result1.tsv ./expected-result1.tsv
