#!/usr/bin/env bash

set -euo pipefail

test_script="dbsnp_reference_liftover_GRCh37"
initial_dir=$(pwd)"/${test_script}"
curr_case=""

# chain files
hg38ToHg19chain="/cleansumstats/external_data/chain_files/hg38ToHg19.over.chain.gz"
hg19ToHg18chain="/cleansumstats/external_data/chain_files/hg19ToHg18.over.chain.gz"
hg19ToHg17chain="/cleansumstats/external_data/chain_files/hg19ToHg17.over.chain.gz"

# fasta file GRCh38
#fasta_ref_GRCh38="/cleansumstats/external_data/fasta_reference/GRCh38_latest_genomic.fna.bgz"
# fasta file GRCh37
#fasta_ref_GRCh38="/cleansumstats/external_data/fasta_reference/GRCh37_latest_genomic.fna.bgz"

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
  chain=${1}

  "${test_script}.sh" ./input.txt "${chain}" "chunk_1" ./observed-result1.txt

  _check_results ./observed-result1.txt ./expected-result1.txt

  echo "- [OK] ${curr_case}"

  cd "${initial_dir}"
}

echo ">> Test ${test_script}"

#=================================================================================
# Cases
#=================================================================================

#---------------------------------------------------------------------------------
# Case 1

_setup "check that we get the expected positions"

cat <<EOF > ./input.txt
chr22 15781861 15781861 22:15781861 rs1167048608 G A,T
chr22 15886178 15886178 22:15886178 rs201771182 C G,T
chr22 19613567 19613567 22:19613567 rs1187200240 G A
chr22 19616424 19616424 22:19616424 rs1382106019 C T
EOF

# In online dbsnp rs1187200240 and rs1382106019 have no positions in GRCh37. 
# But apparently it is possible to get a coordinate by using CrossMap
cat <<EOF > ./expected-result1.txt
chr22 16196102 16196102 22:16196102 22:15781861 rs1167048608 G A,T
chr22 16091785 16091785 22:16091785 22:15886178 rs201771182 C G,T
chr22 19601090 19601090 22:19601090 22:19613567 rs1187200240 G A
chr22 19603947 19603947 22:19603947 22:19616424 rs1382106019 C T
EOF

_run_script "${hg38ToHg19chain}"

#---------------------------------------------------------------------------------
# Next case


