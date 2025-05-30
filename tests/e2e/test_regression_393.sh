#!/usr/bin/env bash

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
project_dir=$(dirname "${tests_dir}")
schemas_dir="${project_dir}/assets/schemas"
work_dir="${project_dir}/tmp/regression-393"
outdir="${work_dir}/out"

rm -rf "${work_dir}"
mkdir "${work_dir}"

echo ">> Test regression #393"

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
study_Ancestry: EUR
study_Gender: mixed
stats_Model: logistic
stats_TraitType: case-control
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
col_ControlEAF: ControlAF
EOF

cat <<EOF > ./input.txt
SNP	CHR	BP	A1	A2	EFFECT_A1	P	Ncase	Ncont	CaseAF	ControlAF
rs284858	chr10	104563926	A	G	0.0187	0.001	140	1257	0.9	0.971942128314025
rs2025468	chr10	10656491	T	C	0.0101	0.002	140	1257	0.9	0.918324827151318
rs1409409	chr10	108121451	T	G	0.005	0.003	140	1257	0.8	0.827019883495658
rs12781860	chr10	108898341	A	C	0.0016	0.201	140	1257	0.95	0.996017639927959
rs1362943	chr10	114878598	T	C	0.018	0.031	140	1257	0.95	0.982071741096079
rs11597279	chr10	28866998	A	C	0.0104	0.021	140	1257	0.95	0.997452448201409
rs12221364	chr10	59007596	A	C	-0.0138	0.401	140	1257	0.8	0.859937164229473
rs10886419	chr10	120953577	C	T	0.0039	0.201	140	1257	0.6	0.620952934138553
EOF

cat <<EOF > ./expected-result1.tsv
CHR	POS	0	RSID	EffectAllele	OtherAllele	B	P	Neff	CaseN	ControlN	EAF	CaseEAF	ControlEAF	EAF_1KG
10	102814179	1	rs284858	T	C	0.0187	0.001	503.879742	140	1257	0.964732	0.9	0.971942128314025	0.41
10	10574522	2	rs2025468	T	C	0.0101	0.002	503.879742	140	1257	0.916488	0.9	0.918324827151318	0.82
10	106371703	3	rs1409409	C	A	-0.005	0.003	503.879742	140	1257	0.175688	0.2	0.17298	0.84
10	107148593	4	rs12781860	A	C	0.0016	0.201	503.879742	140	1257	0.991406	0.95	0.996017639927959	0.92
10	113128849	5	rs1362943	G	A	-0.018	0.031	503.879742	140	1257	0.021142	0.05	0.0179283	0.72
10	119204075	8	rs10886419	T	C	-0.0039	0.201	503.879742	140	1257	0.381147	0.4	0.379047	0.72
10	28538063	6	rs11597279	T	G	0.0104	0.021	503.879742	140	1257	0.992697	0.95	0.997452448201409	0.7
10	57577830	7	rs12221364	G	T	0.0138	0.401	503.879742	140	1257	0.146070	0.2	0.140063	0.49
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

    echo "- [FAIL] regression-393"
    cat ./difference
    exit 1
  fi

}

mv ${outdir}/cleaned_GRCh38 ./observed-result1.tsv
_check_results ./observed-result1.tsv ./expected-result1.tsv

