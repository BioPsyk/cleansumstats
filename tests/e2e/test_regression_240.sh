#!/usr/bin/env bash

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
project_dir=$(dirname "${tests_dir}")
schemas_dir="${project_dir}/assets/schemas"
work_dir="${project_dir}/tmp/regression-240"
outdir="${work_dir}/out"
log_dir="${project_dir}/test_logs"

# Create log directory if it doesn't exist
mkdir -p "${log_dir}"

echo "regression-240-started"

# Redirect all output to log file
exec > "${log_dir}/regression-240.log" 2>&1

rm -rf "${work_dir}"
mkdir "${work_dir}"

echo ">> Test regression #240"

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
rs6459415	chr6	15946099	T	C	0.867	0.0292	0.0202	0.1489
rs6461547	chr7	21082528	A	G	0.3	-7e-04	0.0146	0.9616
rs6463169	chr7	42980893	T	C	0.825	-0.0219	0.0171	0.2012
rs6463263	chr7	44839271	T	C	0.94	-0.0029	0.0282	0.9168
rs6472122	chr8	64855114	A	G	0.017	0.0216	0.0335	0.5194
rs6477547	chr9	106724420	T	C	0.342	-0.0019	0.0137	0.8877
rs6477799	chr9	110790992	A	G	0.192	0.0105	0.0147	0.4765
rs6479789	chr10	63617975	T	C	0.822	0.0048	0.0168	0.7762
rs648778	chr10	6574598	A	G	0.283	0.0123	0.0134	0.3595
rs6490245	chr12	118123883	A	G	0.525	0.0038	0.0128	0.7666
rs6492169	chr13	108637224	T	C	0.283	5e-04	0.0142	0.9703
rs6492836	chr13	95632405	T	G	0.788	3e-04	0.0168	0.9866
rs6496603	chr15	88130196	A	G	0.636	-0.012	0.0134	0.3724
rs6500253	chr16	46639397	T	C	0.908	-5e-04	0.0199	0.9798
rs6508587	chr18	25259071	A	G	0.525	0.0041	0.0132	0.7589
rs6508758	chr19	43222962	T	G	0.792	-0.0158	0.0152	0.299
rs6515304	chr20	23066199	T	C	0.475	0.0112	0.013	0.3897
rs6519694	chr22	25797542	A	G	0.775	-0.0175	0.0167	0.2953
rs6537512	chr10	50108861	A	G	0.942	-0.0081	0.0283	0.775
rs6538385	chr12	92009537	T	C	0.186	-0.0026	0.0166	0.8757
rs10831632	chr11	11504758	A	G	0.305	0.0095	0.0144	0.5085
rs6542464	chr2	118947522	T	C	0.108	0.0126	0.0175	0.4733
rs6546646	chr2	71013058	A	G	0.125	-0.0238	0.0171	0.1643
rs6549009	chr3	85169093	A	G	0.742	-0.0065	0.0136	0.6331
rs6551665	chr4	62568307	A	G	0.692	0.0055	0.0133	0.6802
rs655497	chr9	22436828	A	G	0.725	0.0392	0.0141	0.00534
rs6556405	chr5	158567680	T	C	0.767	-0.0027	0.0148	0.8563
rs655929	chr11	119398389	A	C	0.492	-0.002	0.0128	0.8782
rs6563808	chr13	39664662	T	C	0.212	-8e-04	0.0143	0.9534
rs6563969	chr16	82282393	A	G	0.602	-0.02	0.0128	0.1185
rs6564905	chr16	80222903	T	C	0.3	-0.0023	0.0136	0.8669
rs6568634	chr6	110599381	A	G	0.915	0.0539	0.0232	0.01989
rs6573309	chr14	23232107	A	C	0.792	0.0219	0.0169	0.1944
rs6584223	chr10	100577961	A	G	0.808	-0.0375	0.0158	0.01741
rs6586155	chr10	82461812	T	C	0.133	0.0188	0.0203	0.3523
rs658724	chr3	61790490	T	G	0.585	0.0038	0.0131	0.7706
rs10835608	chr11	29992753	T	C	0.192	0.0141	0.0153	0.3566
rs6593989	chr1	200695833	A	G	0.559	-0.0279	0.0129	0.03119
rs6595018	chr5	116577680	T	C	0.208	0.0013	0.0157	0.9328
rs6600278	chr1	39073644	T	C	0.942	-0.0049	0.0299	0.8689
rs6602676	chr10	13810071	T	C	0.559	0.0047	0.0128	0.7147
EOF

cat <<EOF > ./expected-result1.tsv
CHR	POS	0	RSID	EffectAllele	OtherAllele	B	SE	Z	P	EAF_1KG
10	49230810	26	rs6537512	G	A	0.0081	0.0283	0.286219	1.67880e-01	0.06
10	62188210	15	rs6479789	T	C	0.0048	0.0168	0.285714	1.67417e-01	0.82
11	120022470	35	rs655929	C	A	0.002	0.0128	0.156250	1.32373e-01	0.49
11	30014630	44	rs10835608	C	T	-0.0141	0.0153	-0.921569	4.39947e-01	0.76
12	117668628	5	rs645510	C	T	0.0151	0.0143	1.055944	5.10505e-01	0.33
12	93113293	27	rs6538385	C	T	0.0026	0.0166	0.156627	1.33137e-01	0.81
14	23693058	40	rs6573309	C	A	-0.0219	0.0169	-1.295858	6.39146e-01	0.17
15	89785961	20	rs6496603	A	G	-0.012	0.0134	-0.895522	4.24229e-01	0.65
16	48047985	21	rs6500253	T	C	-0.0005	0.0199	-0.025126	1.04761e-01	0.88
16	83691287	37	rs6563969	A	G	-0.02	0.0128	-1.562500	7.61202e-01	0.58
1	38938879	47	rs6600278	C	T	0.0049	0.0299	0.163880	1.35238e-01	0.05
20	23137562	24	rs6515304	T	C	0.0112	0.013	0.861538	4.07662e-01	0.43
3	140461721	1	rs6439928	T	C	-0.0157	0.0141	-1.113475	5.43501e-01	0.68
3	85037252	31	rs6549009	G	A	0.0065	0.0136	0.477941	2.32756e-01	0.29
4	61873823	32	rs6551665	G	A	-0.0055	0.0133	-0.413534	2.08833e-01	0.35
7	43168054	10	rs6463169	C	T	0.0219	0.0171	1.280702	6.29216e-01	0.21
8	63780003	12	rs6472122	G	A	-0.0216	0.0335	-0.644776	3.02413e-01	0.96
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
  echo "regression-240-failed" > /dev/stderr
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
   echo "obs-------obs---------------"
   cat $obs
   echo "exp-------exp--------------"
   cat $exp
   echo "---------------------------"
   cat ./difference
   echo "regression-240-failed" > /dev/stderr
   exit 1
  fi
}

mv ${outdir}/cleaned_GRCh38 ./observed-result1.tsv
_check_results ./observed-result1.tsv ./expected-result1.tsv

echo "regression-240-succeeded" > /dev/stderr
