#!/usr/bin/env bash

# Check that the neglog10P converter does as expected
# see issue-106

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
project_dir=$(dirname "${tests_dir}")
schemas_dir="${project_dir}/assets/schemas"
work_dir="${project_dir}/tmp/regression-197"
outdir="${work_dir}/out"

rm -rf "${work_dir}"
mkdir "${work_dir}"

echo ">> Test regression #197"

cd "${work_dir}"

cat <<EOF > ./input.vcf
##fileformat=VCFv4.0
##fileDate=20180418
##source=dbSNP
##dbSNP_BUILD_ID=151
##reference=GRCh38.p7
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO
22	15886178	rs201771182	C	G,T	.	.	RS=2025468;RSPOS=10574522;dbSNPBuildID=94;SSR=0;SAO=0;VP=0x05010008000517053e000100;GENEINFO=CELF2:10659;WGT=1;VC=SNV;SLO;INT;ASP;VLD;G5A;G5;HD;GNO;KGPhase1;KGPhase3;CAF=0.7678,0.2322;COMMON=1;TOPMED=0.77599388379204892,0.22400611620795107
22	19613567	rs1187200240	G	A	.	.	RS=4836959;RSPOS=124037864;dbSNPBuildID=111;SSR=0;SAO=0;VP=0x05010008000517053e000100;GENEINFO=LOC107987037:107987037;WGT=1;VC=SNV;SLO;INT;ASP;VLD;G5A;G5;HD;GNO;KGPhase1;KGPhase3;CAF=0.4527,0.5473;COMMON=1;TOPMED=0.46554058358817533,0.53445941641182466
22	19616424	rs1382106019	C	T	.	.	RS=7792011;RSPOS=13616840;dbSNPBuildID=116;SSR=0;SAO=0;VP=0x050100080005150536000100;GENEINFO=LOC107986770:107986770;WGT=1;VC=SNV;SLO;INT;ASP;VLD;G5;HD;GNO;KGPhase1;KGPhase3;CAF=0.9185,0.08147;COMMON=1;TOPMED=0.92963971712538226,0.07036028287461773
EOF
gzip "./input.vcf"

# rs201771182 - identified as an SNP complicated to liftover and is sensitive to the 0-position system
# rs1187200240 - it doesn't exist in GRCh37 according to web resources, but we still get it from liftover. I think it is fine.
# rs1382106019 - it doesn't exist in GRCh37 according to web resources, but we still get it from liftover. I think it is fine.

# There is an empty line at the top right now. It won't be a problem for the analysis, but it looks ugly så can be worth removing
cat <<EOF > ./expected-result-grch37-grch38.txt
    
22:16091785 22:15886178 rs201771182 C G,T
22:19601090 22:19613567 rs1187200240 G A
22:19603947 22:19616424 rs1382106019 C T
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
  echo "---------------------------"
  cat $obs
  echo "---------------------------"
  cat $exp
  echo "---------------------------"

    echo "- [FAIL] regression-197"
    cat ./difference
    exit 1
  fi

}

mv ${outdir}/All_20180418_GRCh37_GRCh38.sorted.bed ./observed-result1.txt
_check_results ./observed-result1.txt ./expected-result-grch37-grch38.txt
