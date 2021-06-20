#!/usr/bin/env bash

# Check that the neglog10P converter does as expected
# see issue-106

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
project_dir=$(dirname "${tests_dir}")
schemas_dir="${project_dir}/assets/schemas"
work_dir="${project_dir}/tmp/regression-201"
outdir="${work_dir}/out"

rm -rf "${work_dir}"
mkdir "${work_dir}"

echo ">> Test regression #201"

cd "${work_dir}"

cat <<EOF > ./input.vcf
##fileformat=VCFv4.0
##fileDate=20180418
##source=dbSNP
##dbSNP_BUILD_ID=151
##reference=GRCh38.p7
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
10	38941571	rs1269049638	C	T	.	.	RS=2025468;RSPOS=10574522;dbSNPBuildID=94;SSR=0;SAO=0;VP=0x05010008000517053e000100;GENEINFO=CELF2:10659;WGT=1;VC=SNV;SLO;INT;ASP;VLD;G5A;G5;HD;GNO;KGPhase1;KGPhase3;CAF=0.7678,0.2322;COMMON=1;TOPMED=0.77599388379204892,0.22400611620795107
16	34801626	rs1187863544	C	T	.	.	RS=2025468;RSPOS=10574522;dbSNPBuildID=94;SSR=0;SAO=0;VP=0x05010008000517053e000100;GENEINFO=CELF2:10659;WGT=1;VC=SNV;SLO;INT;ASP;VLD;G5A;G5;HD;GNO;KGPhase1;KGPhase3;CAF=0.7678,0.2322;COMMON=1;TOPMED=0.77599388379204892,0.22400611620795107
22	16386496	rs20763359	C	T	.	.	RS=2025468;RSPOS=10574522;dbSNPBuildID=94;SSR=0;SAO=0;VP=0x05010008000517053e000100;GENEINFO=CELF2:10659;WGT=1;VC=SNV;SLO;INT;ASP;VLD;G5A;G5;HD;GNO;KGPhase1;KGPhase3;CAF=0.7678,0.2322;COMMON=1;TOPMED=0.77599388379204892,0.22400611620795107
EOF
gzip "./input.vcf"

# rs1269049638 - identified as an SNP complicated to liftover resulting in duplicates
# rs1187863544 - identified as an SNP complicated to liftover resulting in duplicates
# rs20763359 - identified as an SNP complicated to liftover resulting in duplicates

# Without duplicate chr:pos we would get this result:
#22:16867158 10:38941571 rs1269049638 C T
#22:16867158 16:34801626 rs1187863544 C T
#22:16867158 22:16386496 rs20763359 C T

# But for simplicity all of these should be removed, as we can treat them as not-reliable

# There is an empty line at the top right now. It won't be a problem for the analysis, but it looks ugly så can be worth removing
cat <<EOF > ./expected-result-grch37-grch38.txt
EOF

time nextflow -q run -offline \
     -work-dir "${work_dir}" \
     "/cleansumstats" \
     --dev true \
     --generateDbSNPreference \
     --input "input.vcf.gz" \
     --outdir "${outdir}" \
     --libdirdbsnp "${outdir}" 
if [[ $? != 0 ]]
then
  cat .nextflow.log
  exit 1
fi

echo "-- Pipeline done"

function _check_results {
  obs=$1
  exp=$2
  if ! diff -u ${obs} ${exp} &> ./difference; then
  echo "----observed-----------------"
  cat $obs
  echo "----expected-----------------"
  cat $exp
  echo "-----------------------------"

    echo "- [FAIL] regression-201"
    cat ./difference
    exit 1
  fi

}

mv ${outdir}/All_20180418_GRCh37_GRCh38.sorted.bed ./observed-result1.txt
_check_results ./observed-result1.txt ./expected-result-grch37-grch38.txt
