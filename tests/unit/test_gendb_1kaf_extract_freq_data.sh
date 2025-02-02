#!/usr/bin/env bash

set -euo pipefail

test_script="gendb_1kaf_extract_freq_data"
initial_dir=$(pwd)"/${test_script}"
curr_case=""

mkdir -p "${initial_dir}"
cd "${initial_dir}"

#=================================================================================
# Helpers
#=================================================================================

function _setup {
  mkdir -p "${1}"
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
  "${test_script}.sh" ./input.vcf "${1}" > ./observed-result1.txt

  _check_results ./observed-result1.txt ./expected-result1.txt

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Case 1: Original format

_setup "original format with SNPs and indels"

# Create test VCF
cat <<EOF > ./input.vcf
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
1	1000	rs1	A	G	.	PASS	EAS_AF=0.1;EUR_AF=0.2;AFR_AF=0.3;AMR_AF=0.4;SAS_AF=0.5
1	2000	rs2	A	GT	.	PASS	EAS_AF=0.1;EUR_AF=0.2;AFR_AF=0.3;AMR_AF=0.4;SAS_AF=0.5
1	3000	rs3	T	C	.	PASS	EAS_AF=0.6;EUR_AF=0.7;AFR_AF=0.8;AMR_AF=0.9;SAS_AF=1.0
EOF

# Create expected output
cat <<EOF > ./expected-result1.txt
CHRPOS	REF	ALT	EAS	EUR	AFR	AMR	SAS
1:1000	A	G	0.1	0.2	0.3	0.4	0.5
1:3000	T	C	0.6	0.7	0.8	0.9	1.0
EOF

_run_script "original"

#---------------------------------------------------------------------------------
# Case 2: 2024 format

_setup "2024 format with duplicates"

# Create test VCF
cat <<EOF > ./input.vcf
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
1	1000	rs1	A	G	.	PASS	EAS=0.1;EUR=0.2;AFR=0.3;AMR=0.4;SAS=0.5
1	1000	rs1	A	G	.	PASS	EAS=0.1;EUR=0.2;AFR=0.3;AMR=0.4;SAS=0.5
1	2000	rs2	A	GT	.	PASS	EAS=0.1;EUR=0.2;AFR=0.3;AMR=0.4;SAS=0.5
1	3000	rs3	T	C	.	PASS	EAS=0.6;EUR=0.7;AFR=0.8;AMR=0.9;SAS=1.0
EOF

# Create expected output
cat <<EOF > ./expected-result1.txt
CHRPOS	REF	ALT	EAS	EUR	AFR	AMR	SAS
1:1000	A	G	0.1	0.2	0.3	0.4	0.5
1:3000	T	C	0.6	0.7	0.8	0.9	1.0
EOF

_run_script "2024-09-11-1000GENOMES-phase_3.vcf"

#---------------------------------------------------------------------------------
# Case 3: Invalid format

_setup "invalid format"

cat <<EOF > ./input.vcf
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
1	1000	rs1	A	G	.	PASS	EAS_AF=0.1;EUR_AF=0.2;AFR_AF=0.3;AMR_AF=0.4;SAS_AF=0.5
EOF

cat <<EOF > ./expected-result1.txt
not valid ftype for allele frequency extraction
EOF

if ! "${test_script}.sh" ./input.vcf "invalid" 2>&1 | grep -q "not valid ftype for allele frequency extraction"; then
  echo "- [FAIL] ${curr_case}: Expected error message not found"
  exit 1
fi

cd "${initial_dir}"

echo "All tests passed!" 