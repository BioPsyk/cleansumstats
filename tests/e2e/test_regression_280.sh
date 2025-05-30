#!/usr/bin/env bash

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
project_dir=$(dirname "${tests_dir}")
schemas_dir="${project_dir}/assets/schemas"
work_dir="${project_dir}/tmp/regression-280"
outdir="${work_dir}/out"

rm -rf "${work_dir}"
mkdir "${work_dir}"

echo ">> Test regression #280"

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
stats_neglog10P: false
stats_log10P: false
col_BETA: EFFECT_A1
col_CHR: CHR
col_EffectAllele: A1
col_OtherAllele: A2
col_P: P
col_POS: BP
col_SNP: SNP
col_OAF: OAF
col_CaseEAF: CaEAF
col_ControlOAF: CoOAF
EOF

cat <<EOF > ./input.txt
SNP	CHR	BP	A1	A2	EFFECT_A1	CaEAF	CoOAF	P	OAF
rs284858	chr10	104563926	A	G	0.0187	0.2	0.3	0.001	0.2
rs2025468	chr10	10656491	T	C	0.0101	0.2	0.1	0.002	0.2
rs1409409	chr10	108121451	T	G	0.005	0.3	0.2	0.003	0.3
rs12781860	chr10	108898341	A	C	0.0016	0.4	0.5	0.201	0.2
rs1362943	chr10	114878598	T	C	0.018	0.4	0.5	0.031	0.1
rs11597279	chr10	28866998	A	C	0.0104	0.9	0.8	0.021	0.5
rs12221364	chr10	59007596	A	C	-0.0138	0.4	0.5	0.401	0.8
rs10886419	chr10	120953577	C	T	0.0039	0.2	0.3	0.201	0.2
EOF

cat <<EOF > ./expected-result1.tsv
CHR	POS	0	RSID	EffectAllele	OtherAllele	B	Z	P	EAF	CaseEAF	ControlEAF	EAF_1KG
10	102814179	1	rs284858	T	C	0.0187	3.290527	0.001	0.8	0.2	0.7	0.41
10	10574522	2	rs2025468	T	C	0.0101	3.090232	0.002	0.8	0.2	0.9	0.82
10	106371703	3	rs1409409	C	A	-0.005	-2.967738	0.003	0.3	0.7	0.2	0.84
10	107148593	4	rs12781860	A	C	0.0016	1.278708	0.201	0.8	0.4	0.5	0.92
10	113128849	5	rs1362943	G	A	-0.018	-2.157073	0.031	0.1	0.6	0.5	0.72
10	119204075	8	rs10886419	T	C	-0.0039	-1.278708	0.201	0.2	0.8	0.3	0.72
10	28538063	6	rs11597279	T	G	0.0104	2.307984	0.021	0.5	0.9	0.2	0.7
10	57577830	7	rs12221364	G	T	0.0138	0.839837	0.401	0.8	0.6	0.5	0.49
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

# check top rows
#ls ${outdir}
#zcat ${outdir}/cleaned_GRCh38.gz | head -n3

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

    echo "- [FAIL] regression-280"
    cat ./difference
    exit 1
  fi

}

mv ${outdir}/cleaned_GRCh38 ./observed-result1.tsv
_check_results ./observed-result1.tsv ./expected-result1.tsv

