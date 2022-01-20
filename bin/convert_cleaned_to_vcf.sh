#!/bin/bash

sfile=${1}
out=${2}
cleanup=${3}

if ${cleanup} ;then
  tmp_dir=$(mktemp -d)
  
  function cleanup()
  {
    cd "${test_dir}"
    rm -rf "${tmp_dir}"
  }
  
  trap cleanup EXIT
  cd "${tmp_dir}"
fi

VarToSearchFor=(
B
SE
Z
P
N
CaseN
EAF
INFO
)

VarToUseAsName=(
ES
SE
EZ
EP
SS
NC
AF
SI
)

FormatFlags=(
'##FORMAT=<ID=ES,Number=A,Type=Float,Description="Effect size estimate relative to the alternative allele">'
'##FORMAT=<ID=SE,Number=A,Type=Float,Description="Standard error of effect size estimate">'
'##FORMAT=<ID=EZ,Number=A,Type=Float,Description="Z-score of effect size estimate">'
'##FORMAT=<ID=EP,Number=A,Type=Float,Description="p-value for effect estimate">'
'##FORMAT=<ID=SS,Number=A,Type=Integer,Description="Sample size used to estimate genetic effect">'
'##FORMAT=<ID=NC,Number=A,Type=Integer,Description="Number of cases used to estimate genetic effect">'
'##FORMAT=<ID=AF,Number=A,Type=Float,Description="Reference allele frequency">'
'##FORMAT=<ID=SI,Number=A,Type=Float,Description="Accuracy score of summary data imputation">'
)

# if not found, then 0
function var_position_each(){
  var=$1
  fil=$2
  zcat $fil | head -n1 | awk -vFS="\t" -vvar="${var}" '{for(i=1; i<NF; i++){if($i==var){print i;next}}; print 0}'
}

#get position and available names
function var_position_all(){
  i=0
  for var in "${VarToSearchFor[@]}"; do
    vp="$(var_position_each $var $sfile)"
    if [ "${vp}" != "0" ];then
      echo "${vp}"
      echo "${VarToUseAsName[${i}]}" 1>&2
    else
      :
    fi
    i=$((i+1))
  done
}

function add_header_format_meta(){
  i=0
  for var in "${VarToSearchFor[@]}"; do
    vp="$(var_position_each $var $sfile)"
    if [ "${vp}" != "0" ];then
      echo "${FormatFlags[${i}]}"
    else
      :
    fi
    i=$((i+1))
  done
}

pos_k=$(var_position_all 2> /dev/null | awk '{printf "%s|", $1}' | sed 's/|$//')
nam_k=$(var_position_all 2>&1 > /dev/null | awk '{printf "%s:", $1}' | sed 's/:$//')

# Add AF as INFO field later if needed
##INFO=<ID=AF,Number=A,Type=Float,Description="Allele Frequency">

# Add META later if needed
#'##META=<ID=TotalVariants,Number=1,Type=Integer,Description="Total number of variants in input">'
#'##META=<ID=VariantsNotRead,Number=1,Type=Integer,Description="Number of variants that could not be read">'
#'##META=<ID=HarmonisedVariants,Number=1,Type=Integer,Description="Total number of harmonised variants">'
#'##META=<ID=VariantsNotHarmonised,Number=1,Type=Integer,Description="Total number of variants that could not be harmonised">'
#'##META=<ID=SwitchedAlleles,Number=1,Type=Integer,Description="Total number of variants strand switched">'
#'##META=<ID=TotalControls,Number=1,Type=Integer,Description="Total number of controls in the association study">'
#'##META=<ID=TotalCases,Number=1,Type=Integer,Description="Total number of cases in the association study">'
#'##META=<ID=StudyType,Number=1,Type=String,Description="Type of GWAS study [Continuous or CaseControl]">'

# prepare outfile sumstat as tabix sorted vcf
printf -v date '%(%Y%m%d)T' -1

cat <<EOF > tmp1
##fileformat=VCFv4.3
##FILTER=<ID=PASS,Description="All filters passed">
##fileDate=${date}
##source=cleansumstats
EOF

add_header_format_meta >> tmp1

# Make the header row
echo -e "#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	sumstats" >> tmp1

# Make remaining rows
zcat $sfile | awk -vOFS="\t" -vformat="${nam_k}" -vpos="${pos_k}" '
NR>1{
  split(pos,sp,"|"); 
  printf "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s", $1,OFS,$2,OFS,$4,OFS,$5,OFS,$6,OFS,".",OFS,"PASS",OFS,".",OFS,format;
  if(length(sp)>=1){printf "%s%s",OFS, $(sp[1])};
  for (i=2; i <= length(sp); i++){printf "%s%s", ":",$(sp[i])}; 
  printf "\n"}' > tmp2

# sort and make tabix index
sort -t "$(printf '\t')" -k1,1 -k2,2n tmp2 > tmp2b

# merge with header
cat tmp1 tmp2b > tmp3

# bgzip and tabix (so that we can use bcftools)
bgzip -c tmp3 > ${out}
tabix -p vcf ${out}

