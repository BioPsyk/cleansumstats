#!/usr/bin/env bash

set -euo pipefail

test_script="dbsnp_reference_filter_and_convert"
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

mapfile="/cleansumstats/assets/allowed_ncbi_chromosome_names"
function _run_script {
  chromtype=${1}

  cat ./input.txt | "${test_script}.sh" ${mapfile} ${chromtype} > ./observed-result1.txt

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
NC_000001.11	10001	rs1570391677	T	A,C	.	.	RS=1570391677;dbSNPBuildID=154;SSR=0;PSEUDOGENEINFO=DDX11L1:100287102;VC=SNV;R5;GNO;FREQ=KOREAN:0.9891,0.0109,.|SGDP_PRJ:0,1,.|dbGaP_PopFreq:1,.,0;COMMON
NC_000003.12	10002	rs1570391692	A	C	.	.	RS=1570391692;dbSNPBuildID=154;SSR=0;PSEUDOGENEINFO=DDX11L1:100287102;VC=SNV;R5;GNO;FREQ=KOREAN:0.9944,0.005597
NT_167248.2	10003	rs1570391694	A	C	.	.	RS=1570391694;dbSNPBuildID=154;SSR=0;PSEUDOGENEINFO=DDX11L1:100287102;VC=SNV;R5;GNO;FREQ=KOREAN:0.9902,0.009763
NC_000023.11	10007	rs1639538116	T	C,G	.	.	RS=1639538116;SSR=0;PSEUDOGENEINFO=DDX11L1:100287102;VC=SNV;R5;GNO;FREQ=dbGaP_PopFreq:1,0,0
NC_012920.1	10008	rs1570391698	A	C,G,T	.	.	RS=1570391698;dbSNPBuildID=154;SSR=0;PSEUDOGENEINFO=DDX11L1:100287102;VC=SNV;R5;GNO;FREQ=KOREAN:0.9969,.,0.003086,.|dbGaP_PopFreq:1,0,.,0
EOF

cat <<EOF > ./expected-result1.txt
1	10001	rs1570391677	T	A,C	.	.	RS=1570391677;dbSNPBuildID=154;SSR=0;PSEUDOGENEINFO=DDX11L1:100287102;VC=SNV;R5;GNO;FREQ=KOREAN:0.9891,0.0109,.|SGDP_PRJ:0,1,.|dbGaP_PopFreq:1,.,0;COMMON
3	10002	rs1570391692	A	C	.	.	RS=1570391692;dbSNPBuildID=154;SSR=0;PSEUDOGENEINFO=DDX11L1:100287102;VC=SNV;R5;GNO;FREQ=KOREAN:0.9944,0.005597
23	10007	rs1639538116	T	C,G	.	.	RS=1639538116;SSR=0;PSEUDOGENEINFO=DDX11L1:100287102;VC=SNV;R5;GNO;FREQ=dbGaP_PopFreq:1,0,0
26	10008	rs1570391698	A	C,G,T	.	.	RS=1570391698;dbSNPBuildID=154;SSR=0;PSEUDOGENEINFO=DDX11L1:100287102;VC=SNV;R5;GNO;FREQ=KOREAN:0.9969,.,0.003086,.|dbGaP_PopFreq:1,0,.,0
EOF

_run_script "ncbi"

#---------------------------------------------------------------------------------
# Next case


