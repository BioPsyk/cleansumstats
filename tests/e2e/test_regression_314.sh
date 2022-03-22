#!/usr/bin/env bash

set -euo pipefail

e2e_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
tests_dir=$(dirname "${e2e_dir}")
project_dir=$(dirname "${tests_dir}")
schemas_dir="${project_dir}/assets/schemas"
work_dir="${project_dir}/tmp/regression-314"
outdir="${work_dir}/out"

rm -rf "${work_dir}"
mkdir "${work_dir}"

echo ">> Test regression #314"

cd "${work_dir}"

#First 6 rows are not duplicates in GRCh35, but the rest are duplicates in GRCh35
cat <<EOF | gzip -c > ./input.vcf.gz
##fileformat=VCFv4.0
##fileDate=20180418
##source=dbSNP
##dbSNP_BUILD_ID=151
##reference=GRCh38.p7
##phasing=partial
##variationPropertyDocumentationUrl=ftp://ftp.ncbi.nlm.nih.gov/snp/specs/dbSNP_BitField_latest.pdf
##INFO=<ID=RS,Number=1,Type=Integer,Description="dbSNP ID (i.e. rs number)">
##INFO=<ID=RSPOS,Number=1,Type=Integer,Description="Chr position reported in dbSNP">
##INFO=<ID=RV,Number=0,Type=Flag,Description="RS orientation is reversed">
##INFO=<ID=VP,Number=1,Type=String,Description="Variation Property.  Documentation is at ftp://ftp.ncbi.nlm.nih.gov/snp/specs/dbSNP_BitField_latest.pdf">
##INFO=<ID=GENEINFO,Number=1,Type=String,Description="Pairs each of gene symbol:gene id.  The gene symbol and id are delimited by a colon (:) and each pair is delimited by a vertical bar (|)">
##INFO=<ID=dbSNPBuildID,Number=1,Type=Integer,Description="First dbSNP Build for RS">
##INFO=<ID=SAO,Number=1,Type=Integer,Description="Variant Allele Origin: 0 - unspecified, 1 - Germline, 2 - Somatic, 3 - Both">
##INFO=<ID=SSR,Number=1,Type=Integer,Description="Variant Suspect Reason Codes (may be more than one value added together) 0 - unspecified, 1 - Paralog, 2 - byEST, 4 - oldAlign, 8 - Para_EST, 16 - 1kg_failed, 1024 - other">
##INFO=<ID=WGT,Number=1,Type=Integer,Description="Weight, 00 - unmapped, 1 - weight 1, 2 - weight 2, 3 - weight 3 or more">
##INFO=<ID=VC,Number=1,Type=String,Description="Variation Class">
##INFO=<ID=PM,Number=0,Type=Flag,Description="Variant is Precious(Clinical,Pubmed Cited)">
##INFO=<ID=TPA,Number=0,Type=Flag,Description="Provisional Third Party Annotation(TPA) (currently rs from PHARMGKB who will give phenotype data)">
##INFO=<ID=PMC,Number=0,Type=Flag,Description="Links exist to PubMed Central article">
##INFO=<ID=S3D,Number=0,Type=Flag,Description="Has 3D structure - SNP3D table">
##INFO=<ID=SLO,Number=0,Type=Flag,Description="Has SubmitterLinkOut - From SNP->SubSNP->Batch.link_out">
##INFO=<ID=NSF,Number=0,Type=Flag,Description="Has non-synonymous frameshift A coding region variation where one allele in the set changes all downstream amino acids. FxnClass = 44">
##INFO=<ID=NSM,Number=0,Type=Flag,Description="Has non-synonymous missense A coding region variation where one allele in the set changes protein peptide. FxnClass = 42">
##INFO=<ID=NSN,Number=0,Type=Flag,Description="Has non-synonymous nonsense A coding region variation where one allele in the set changes to STOP codon (TER). FxnClass = 41">
##INFO=<ID=REF,Number=0,Type=Flag,Description="Has reference A coding region variation where one allele in the set is identical to the reference sequence. FxnCode = 8">
##INFO=<ID=SYN,Number=0,Type=Flag,Description="Has synonymous A coding region variation where one allele in the set does not change the encoded amino acid. FxnCode = 3">
##INFO=<ID=U3,Number=0,Type=Flag,Description="In 3' UTR Location is in an untranslated region (UTR). FxnCode = 53">
##INFO=<ID=U5,Number=0,Type=Flag,Description="In 5' UTR Location is in an untranslated region (UTR). FxnCode = 55">
##INFO=<ID=ASS,Number=0,Type=Flag,Description="In acceptor splice site FxnCode = 73">
##INFO=<ID=DSS,Number=0,Type=Flag,Description="In donor splice-site FxnCode = 75">
##INFO=<ID=INT,Number=0,Type=Flag,Description="In Intron FxnCode = 6">
##INFO=<ID=R3,Number=0,Type=Flag,Description="In 3' gene region FxnCode = 13">
##INFO=<ID=R5,Number=0,Type=Flag,Description="In 5' gene region FxnCode = 15">
##INFO=<ID=OTH,Number=0,Type=Flag,Description="Has other variant with exactly the same set of mapped positions on NCBI refernce assembly.">
##INFO=<ID=CFL,Number=0,Type=Flag,Description="Has Assembly conflict. This is for weight 1 and 2 variant that maps to different chromosomes on different assemblies.">
##INFO=<ID=ASP,Number=0,Type=Flag,Description="Is Assembly specific. This is set if the variant only maps to one assembly">
##INFO=<ID=MUT,Number=0,Type=Flag,Description="Is mutation (journal citation, explicit fact): a low frequency variation that is cited in journal and other reputable sources">
##INFO=<ID=VLD,Number=0,Type=Flag,Description="Is Validated.  This bit is set if the variant has 2+ minor allele count based on frequency or genotype data.">
##INFO=<ID=G5A,Number=0,Type=Flag,Description=">5% minor allele frequency in each and all populations">
##INFO=<ID=G5,Number=0,Type=Flag,Description=">5% minor allele frequency in 1+ populations">
##INFO=<ID=HD,Number=0,Type=Flag,Description="Marker is on high density genotyping kit (50K density or greater).  The variant may have phenotype associations present in dbGaP.">
##INFO=<ID=GNO,Number=0,Type=Flag,Description="Genotypes available. The variant has individual genotype (in SubInd table).">
##INFO=<ID=KGPhase1,Number=0,Type=Flag,Description="1000 Genome phase 1 (incl. June Interim phase 1)">
##INFO=<ID=KGPhase3,Number=0,Type=Flag,Description="1000 Genome phase 3">
##INFO=<ID=CDA,Number=0,Type=Flag,Description="Variation is interrogated in a clinical diagnostic assay">
##INFO=<ID=LSD,Number=0,Type=Flag,Description="Submitted from a locus-specific database">
##INFO=<ID=MTP,Number=0,Type=Flag,Description="Microattribution/third-party annotation(TPA:GWAS,PAGE)">
##INFO=<ID=OM,Number=0,Type=Flag,Description="Has OMIM/OMIA">
##INFO=<ID=NOC,Number=0,Type=Flag,Description="Contig allele not present in variant allele list. The reference sequence allele at the mapped position is not present in the variant allele list, adjusted for orientation.">
##INFO=<ID=WTD,Number=0,Type=Flag,Description="Is Withdrawn by submitter If one member ss is withdrawn by submitter, then this bit is set.  If all member ss' are withdrawn, then the rs is deleted to SNPHistory">
##INFO=<ID=NOV,Number=0,Type=Flag,Description="Rs cluster has non-overlapping allele sets. True when rs set has more than 2 alleles from different submissions and these sets share no alleles in common.">
##FILTER=<ID=NC,Description="Inconsistent Genotype Submission For At Least One Sample">
##INFO=<ID=CAF,Number=.,Type=String,Description="An ordered, comma delimited list of allele frequencies based on 1000Genomes, starting with the reference allele followed by alternate alleles as ordered in the ALT column. Where a 1000Genomes alternate allele is not in the dbSNPs alternate allele set, the allele is added to the ALT column. The minor allele is the second largest value in the list, and was previuosly reported in VCF as the GMAF. This is the GMAF reported on the RefSNP and EntrezSNP pages and VariationReporter">
##INFO=<ID=COMMON,Number=1,Type=Integer,Description="RS is a common SNP.  A common SNP is one that has at least one 1000Genomes population with a minor allele of frequency >= 1% and for which 2 or more founders contribute to that minor allele frequency.">
##INFO=<ID=TOPMED,Number=.,Type=String,Description="An ordered, comma delimited list of allele frequencies based on TOPMed, starting with the reference allele followed by alternate alleles as ordered in the ALT column. The TOPMed minor allele is the second largest value in the list.">
#CHROM  POS     ID      REF     ALT     QUAL    FILTER  INFO
10      10574522        rs2025468       T       C       .       .       RS=2025468;RSPOS=10574522;dbSNPBuildID=94;SSR=0;SAO=0;VP=0x05010008000517053e000100;GENEINFO=CELF2:10659;WGT=1;VC=SNV;SLO;INT;ASP;VLD;G5A;G5;HD;GNO;KGPhase1;KGPhase3;CAF=0.7678,0.2322;COMMON=1;TOPMED=0.77599388379204892,0.22400611620795107
9       124037864       rs4836959       T       C       .       .       RS=4836959;RSPOS=124037864;dbSNPBuildID=111;SSR=0;SAO=0;VP=0x05010008000517053e000100;GENEINFO=LOC107987037:107987037;WGT=1;VC=SNV;SLO;INT;ASP;VLD;G5A;G5;HD;GNO;KGPhase1;KGPhase3;CAF=0.4527,0.5473;COMMON=1;TOPMED=0.46554058358817533,0.53445941641182466
7       13616840        rs7792011       A       G       .       .       RS=7792011;RSPOS=13616840;dbSNPBuildID=116;SSR=0;SAO=0;VP=0x050100080005150536000100;GENEINFO=LOC107986770:107986770;WGT=1;VC=SNV;SLO;INT;ASP;VLD;G5;HD;GNO;KGPhase1;KGPhase3;CAF=0.9185,0.08147;COMMON=1;TOPMED=0.92963971712538226,0.07036028287461773
2       3476792 rs7592700       G       A       .       .       RS=7592700;RSPOS=3476792;dbSNPBuildID=116;SSR=0;SAO=0;VP=0x05010008000517053e000100;GENEINFO=TRAPPC12:51112;WGT=1;VC=SNV;SLO;INT;ASP;VLD;G5A;G5;HD;GNO;KGPhase1;KGPhase3;CAF=0.3834,0.6166;COMMON=1;TOPMED=0.40190175840978593,0.59809824159021406
22      33723880        rs239315        A       G       .       .       RS=239315;RSPOS=33723880;dbSNPBuildID=79;SSR=0;SAO=0;VP=0x0501000a0005150536000100;GENEINFO=LARGE-AS1:100506195|LARGE1:9215|LARGE:9215;WGT=1;VC=SNV;SLO;INT;R5;ASP;VLD;G5;HD;GNO;KGPhase1;KGPhase3;CAF=0.9115,0.08846;COMMON=1;TOPMED=0.90616239806320081,0.09383760193679918
13      96155517        rs7987510       T       C       .       .       RS=7987510;RSPOS=96155517;dbSNPBuildID=116;SSR=0;SAO=0;VP=0x05010008000517053e000100;GENEINFO=HS6ST3:266722;WGT=1;VC=SNV;SLO;INT;ASP;VLD;G5A;G5;HD;GNO;KGPhase1;KGPhase3;CAF=0.6226,0.3774;COMMON=1;TOPMED=0.61514080020387359,0.38485919979612640
7       130584829       rs1224417682    C       T       .       .       RS=1224417682;RSPOS=130584829;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000080005000002000100;GENEINFO=COPG2:26958;WGT=1;VC=SNV;INT;ASP;TOPMED=0.99998407237512742,0.00001592762487257
7       130584848       rs1329394382    T       C       .       .       RS=1329394382;RSPOS=130584848;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000080005000002000100;GENEINFO=COPG2:26958;WGT=1;VC=SNV;INT;ASP;TOPMED=0.99994425331294597,0.00005574668705402
8       85064463        rs1449309953    C       A       .       .       RS=1449309953;RSPOS=85064463;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000000005000002000100;WGT=1;VC=SNV;ASP
10      10558169        rs1290986714    G       A       .       .       RS=1290986714;RSPOS=10558169;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000080005000002000100;GENEINFO=CELF2:10659;WGT=1;VC=SNV;INT;ASP;TOPMED=0.99999203618756371,0.00000796381243628
10      10558177        rs922583286     T       C       .       .       RS=922583286;RSPOS=10558177;dbSNPBuildID=150;SSR=0;SAO=0;VP=0x050000080005000002000100;GENEINFO=CELF2:10659;WGT=1;VC=SNV;INT;ASP;TOPMED=0.99994425331294597,0.00005574668705402
10      10558181        rs571138900     T       C       .       .       RS=571138900;RSPOS=10558181;dbSNPBuildID=142;SSR=0;SAO=0;VP=0x050000080005040026000100;GENEINFO=CELF2:10659;WGT=1;VC=SNV;INT;ASP;VLD;KGPhase3;CAF=0.9988,0.001198;COMMON=1;TOPMED=0.99957791794087665,0.00042208205912334
10      10558184        rs1292842742    C       T       .       .       RS=1292842742;RSPOS=10558184;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000080005000002000100;GENEINFO=CELF2:10659;WGT=1;VC=SNV;INT;ASP;TOPMED=0.99998407237512742,0.00001592762487257
10      10558202        rs1236167595    G       A       .       .       RS=1236167595;RSPOS=10558202;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000080005000002000100;GENEINFO=CELF2:10659;WGT=1;VC=SNV;INT;ASP;TOPMED=0.99983275993883792,0.00016724006116207
10      10558203        rs1049544728    C       A,T     .       .       RS=1049544728;RSPOS=10558203;dbSNPBuildID=150;SSR=0;SAO=0;VP=0x050000080005000002000100;GENEINFO=CELF2:10659;WGT=1;VC=SNV;INT;ASP;TOPMED=0.99929122069317023,0.00001592762487257,0.00069285168195718
10      10558204        rs1195116107    G       A,T     .       .       RS=1195116107;RSPOS=10558204;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000080005000002000100;GENEINFO=CELF2:10659;WGT=1;VC=SNV;INT;ASP;TOPMED=0.99984868756371049,0.00014334862385321,0.00000796381243628
10      99637817        rs1386914944    C       T       .       .       RS=1386914944;RSPOS=99637817;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000080005000002000100;GENEINFO=SLC25A28:81894|LOC105378450:105378450;WGT=1;VC=SNV;INT;ASP;TOPMED=0.99999203618756371,0.00000796381243628
10      99637836        rs189487571     T       G       .       .       RS=189487571;RSPOS=99637836;dbSNPBuildID=135;SSR=0;SAO=0;VP=0x050100080005000036000100;GENEINFO=SLC25A28:81894|LOC105378450:105378450;WGT=1;VC=SNV;SLO;INT;ASP;KGPhase1;KGPhase3;CAF=0.9998,0.0001997;COMMON=0
10      105728842       rs1287171914    C       A       .       .       RS=1287171914;RSPOS=105728842;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000080005000002000100;GENEINFO=LOC101927549:101927549;WGT=1;VC=SNV;INT;ASP;TOPMED=0.99999203618756371,0.00000796381243628
21      9335858 rs1179994420    G       T       .       .       RS=1179994420;RSPOS=9335858;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000000005000002000100;WGT=1;VC=SNV;ASP;TOPMED=0.99999203618756371,0.00000796381243628
21      9335866 rs1437582377    T       G       .       .       RS=1437582377;RSPOS=9335866;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000000005000002000100;WGT=1;VC=SNV;ASP;TOPMED=0.99999203618756371,0.00000796381243628
21      9335870 rs1365982398    T       C       .       .       RS=1365982398;RSPOS=9335870;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000000005000002000100;WGT=1;VC=SNV;ASP
21      9335873 rs1338618404    C       T       .       .       RS=1338618404;RSPOS=9335873;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000000005000002000100;WGT=1;VC=SNV;ASP;TOPMED=0.99967348369011213,0.00032651630988786
21      9335891 rs1264706424    G       A       .       .       RS=1264706424;RSPOS=9335891;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000000005000002000100;WGT=1;VC=SNV;ASP
21      9335892 rs1459744487    C       T       .       .       RS=1459744487;RSPOS=9335892;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000000005000002000100;WGT=1;VC=SNV;ASP;TOPMED=0.99998407237512742,0.00001592762487257
21      9335893 rs1202608784    G       A       .       .       RS=1202608784;RSPOS=9335893;dbSNPBuildID=151;SSR=0;SAO=0;VP=0x050000000005000002000100;WGT=1;VC=SNV;ASP;TOPMED=0.99963366462793068,0.00036633537206931
EOF

cat <<EOF > ./expected-result1.tsv
EOF

time nextflow -q run -offline \
     -work-dir "${work_dir}" \
     "/cleansumstats" \
       --generateDbSNPreference \
       --input "input.vcf.gz" \
       --dev true \
       --outdir "${outdir}" \
       --libdirdbsnp "${outdir}"

if [[ $? != 0 ]]
then
  cat .nextflow.log
  exit 1
fi

echo "-- Pipeline done, general validation"

function _check_results {
  obs=$1
  exp=$2
  if ! diff -u ${obs} ${exp} &> ./difference; then
   echo "----------obs---------------"
   cat $obs
   echo "----------exp--------------"
   cat $exp
   echo "---------------------------"

    echo "- [FAIL] regression-314"
    cat ./difference
    exit 1
  fi

}
ls ${outdir}
mv ${outdir}/All_20180418_GRCh35_GRCh38.sorted.bed ./observed-result1.tsv
_check_results ./observed-result1.tsv ./expected-result1.tsv

echo "-- Pipeline done, specific test"
