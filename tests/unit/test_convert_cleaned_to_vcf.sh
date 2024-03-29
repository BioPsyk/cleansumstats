#!/usr/bin/env bash

set -euo pipefail

test_script="convert_cleaned_to_vcf"
initial_dir=$(pwd)"/${test_script}"
curr_case=""

mkdir "${initial_dir}"
cd "${initial_dir}"

#=================================================================================
# Helpers
#=================================================================================

function _setup {
  mkdir "${1}"
  cd "${1}"
  curr_case="${1}"
}

function _check_results {
  obs=$1
  exp=$2
  if ! diff ${obs} ${exp} &> ./difference; then
    echo "- [FAIL] ${curr_case}"
    cat ./difference 
    exit 1
  fi

}

function _run_script {
base="${1}"
ref="${2}"
alt="${3}"
  "${test_script}.sh" input.tsv.gz observed-result1.tsv.gz false ${base} ${ref} ${alt}

  _check_results <(zcat observed-result1.tsv.gz | grep -v "##fileDate=") <(zcat expected-result1.tsv.gz | grep -v "##fileDate=")

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# convert sumstat to vcf

_setup "convert sumstat to vcf"

cat <<EOF | gzip -c > input.tsv.gz
CHR	POS	0	RSID	EffectAllele	OtherAllele	P	SE	B	Z	EAF_1KG
10	102814179	1873	rs284858	T	C	0.1592	0.0132	0.0187	1.41667	0.41
10	10574522	1582	rs2025468	T	C	0.5398	0.0165	0.0101	0.612121	0.82
10	106371703	1151	rs1409409	C	A	0.7713	0.0171	-0.005	-0.292398	1
10	107148593	1013	rs12781860	A	C	0.9482	0.0241	0.0016	0.06639	0.92
10	113128849	1129	rs1362943	G	A	0.187	0.0136	-0.018	-1.32353	1
10	118368257	1008	rs12767500	C	T	0.09108	0.0308	-0.052	-1.68831	1
EOF

cat <<EOF | gzip -c > ./expected-result1.tsv.gz
##fileformat=VCFv4.3
##FILTER=<ID=PASS,Description="All filters passed">
##fileDate=20211208
##source=cleansumstats
##FORMAT=<ID=ES,Number=A,Type=Float,Description="Effect size estimate relative to the Reference allele">
##FORMAT=<ID=SE,Number=A,Type=Float,Description="Standard error of effect size estimate">
##FORMAT=<ID=EZ,Number=A,Type=Float,Description="Z-score of effect size estimate">
##FORMAT=<ID=EP,Number=A,Type=Float,Description="p-value for effect estimate">
##FORMAT=<ID=AFKG,Number=A,Type=Float,Description="Reference allele frequency from 1000 genomes project. Population used is defined in the metadata of the summary stats">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	sumstats
10	10574522	rs2025468	T	C	.	PASS	.	ES:SE:EZ:EP:AFKG	0.0101:0.0165:0.612121:0.5398:0.82
10	102814179	rs284858	T	C	.	PASS	.	ES:SE:EZ:EP:AFKG	0.0187:0.0132:1.41667:0.1592:0.41
10	106371703	rs1409409	C	A	.	PASS	.	ES:SE:EZ:EP:AFKG	-0.005:0.0171:-0.292398:0.7713:1
10	107148593	rs12781860	A	C	.	PASS	.	ES:SE:EZ:EP:AFKG	0.0016:0.0241:0.06639:0.9482:0.92
10	113128849	rs1362943	G	A	.	PASS	.	ES:SE:EZ:EP:AFKG	-0.018:0.0136:-1.32353:0.187:1
10	118368257	rs12767500	C	T	.	PASS	.	ES:SE:EZ:EP:AFKG	-0.052:0.0308:-1.68831:0.09108:1
EOF

_run_script "Reference" "5" "6"

#---------------------------------------------------------------------------------
# convert sumstat to vcf using ALT

_setup "Convert sumstat to vcf alternative allele version"

cat <<EOF | gzip -c > input.tsv.gz
CHR	POS	0	RSID	EffectAllele	OtherAllele	P	SE	B	Z	EAF_1KG
10	102814179	1873	rs284858	C	T	0.1592	0.0132	0.0187	1.41667	0.41
10	10574522	1582	rs2025468	C	T	0.5398	0.0165	0.0101	0.612121	0.82
10	106371703	1151	rs1409409	A	C	0.7713	0.0171	-0.005	-0.292398	1
10	107148593	1013	rs12781860	C	A	0.9482	0.0241	0.0016	0.06639	0.92
10	113128849	1129	rs1362943	A	G	0.187	0.0136	-0.018	-1.32353	1
10	118368257	1008	rs12767500	T	C	0.09108	0.0308	-0.052	-1.68831	1
EOF

cat <<EOF | gzip -c > ./expected-result1.tsv.gz
##fileformat=VCFv4.3
##FILTER=<ID=PASS,Description="All filters passed">
##fileDate=20211208
##source=cleansumstats
##FORMAT=<ID=ES,Number=A,Type=Float,Description="Effect size estimate relative to the Alternative allele">
##FORMAT=<ID=SE,Number=A,Type=Float,Description="Standard error of effect size estimate">
##FORMAT=<ID=EZ,Number=A,Type=Float,Description="Z-score of effect size estimate">
##FORMAT=<ID=EP,Number=A,Type=Float,Description="p-value for effect estimate">
##FORMAT=<ID=AFKG,Number=A,Type=Float,Description="Alternative allele frequency from 1000 genomes project. Population used is defined in the metadata of the summary stats">
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	sumstats
10	10574522	rs2025468	T	C	.	PASS	.	ES:SE:EZ:EP:AFKG	0.0101:0.0165:0.612121:0.5398:0.82
10	102814179	rs284858	T	C	.	PASS	.	ES:SE:EZ:EP:AFKG	0.0187:0.0132:1.41667:0.1592:0.41
10	106371703	rs1409409	C	A	.	PASS	.	ES:SE:EZ:EP:AFKG	-0.005:0.0171:-0.292398:0.7713:1
10	107148593	rs12781860	A	C	.	PASS	.	ES:SE:EZ:EP:AFKG	0.0016:0.0241:0.06639:0.9482:0.92
10	113128849	rs1362943	G	A	.	PASS	.	ES:SE:EZ:EP:AFKG	-0.018:0.0136:-1.32353:0.187:1
10	118368257	rs12767500	C	T	.	PASS	.	ES:SE:EZ:EP:AFKG	-0.052:0.0308:-1.68831:0.09108:1
EOF

_run_script "Alternative" "6" "5"

#---------------------------------------------------------------------------------
# Next case
