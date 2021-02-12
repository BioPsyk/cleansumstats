liftedandmapped=$1
filtering=$2
outfileprefix=$3

#split comma separated list into bash array
filterArr=($(echo "${filtering}" | awk '{gsub(/ /, "", $0); print}' | awk '{gsub(/,/, "\n", $0); print}' ))


touch ${outfileprefix}esc_removed_duplicated_rows
touch ${outfileprefix}emoved_duplicated_rows
touch ${outfileprefix}fterLiftoverFiltering_executionorder

cp ${liftedandmapped} ${outfileprefix}gb_unique_rows

#check if no filtering will be applied
if [ "${#filterArr[@]}" -eq 0 ]
then
  applyFilter="no"
else
  applyFilter="yes"
fi

#loop over bash array applying each correspondinng filtering type in the samee order
for var in ${filterArr[@]}; do

#  if [ "${var}" == "duplicated_chrpos_refalt_in_GRCh37" ]
#  then
#
#    #remove all but the first ecnountered row where chr:pos REF and ALT for GRCh37
#    LC_ALL=C sort -k2,2 -k5,5 -k6,6 gb_unique_rows > gb_unique_rows_sorted
#    awk 'BEGIN{r0="initrowhere"} {var=$2"-"$5"-"$6; if(r0!=var){print $0}else{print $0 > "removed_duplicated_rows_GRCh37"}; r0=var}' gb_unique_rows_sorted > gb_unique_rows2
#    awk -vOFS="\t" '{print $3,"duplicated_rows_GRCh37"}' removed_duplicated_rows_GRCh37 >> removed_duplicated_rows
#    #process before and after stats
#    rowsBefore="$(wc -l gb_unique_rows | awk '{print $1}')"
#    rowsAfter="$(wc -l gb_unique_rows2 | awk '{print $1}')"
#    echo -e "$rowsBefore\t$rowsAfter\tRemoved duplicated rows in respect to chr:pos and dbsnp REF/ALT, GRCh37" >> desc_removed_duplicated_rows
#    mv gb_unique_rows2 gb_unique_rows
#    echo "duplicated_chrpos_refalt_in_GRCh37" >> afterLiftoverFiltering_executionorder
#
  if [ "${var}" == "duplicated_chrpos_refalt_in_GRCh38" ]
  then
    #remove all but the first ecnountered row where chr:pos REF and ALT for GRCh38
    LC_ALL=C sort -k1,1 -k4,4 -k5,5 ${outfileprefix}gb_unique_rows > ${outfileprefix}gb_unique_rows_sorted
    touch ${outfileprefix}removed_duplicated_rows_GRCh38
    awk -vpre="${outfileprefix}" 'BEGIN{r0="initrowhere"} {var=$1"-"$4"-"$5; if(r0!=var){print $0}else{print $0 > pre"removed_duplicated_rows_GRCh38"}; r0=var}' ${outfileprefix}gb_unique_rows_sorted > ${outfileprefix}gb_unique_rows2
    awk -vOFS="\t" '{print $2,"duplicated_rows_GRCh38"}' ${outfileprefix}removed_duplicated_rows_GRCh38 >> ${outfileprefix}removed_duplicated_rows
    rowsBefore="$(wc -l ${outfileprefix}gb_unique_rows | awk '{print $1}')"
    rowsAfter="$(wc -l ${outfileprefix}gb_unique_rows2 | awk '{print $1}')"
    echo -e "$rowsBefore\t$rowsAfter\tRemoved duplicated rows in respect to chr:pos and dbsnp REF/ALT, GRCh38" >> ${outfileprefix}desc_removed_duplicated_rows
    mv ${outfileprefix}gb_unique_rows2 ${outfileprefix}gb_unique_rows
    echo "duplicated_chrpos_refalt_in_GRCh38" >> ${outfileprefix}afterLiftoverFiltering_executionorder
  
 # elif [ "${var}" == "duplicated_chrpos_in_GRCh37" ]
 # then
 #   #Filter only on position duplicates (A very hard filter but is good enough for alpha release)
 #   LC_ALL=C sort -k2,2 gb_unique_rows > gb_unique_rows_sorted
 #   touch removed_duplicated_rows_GRCh37_hard
 #   awk 'BEGIN{r0="initrowhere"} {var=$2; if(r0!=var){print $0}else{print $0 > "removed_duplicated_rows_GRCh37_hard"}; r0=var}' gb_unique_rows_sorted > gb_unique_rows2
 #   awk -vOFS="\t" '{print $3,"duplicated_rows_GRCh37_hard"}' removed_duplicated_rows_GRCh37_hard >> removed_duplicated_rows
 #   rowsBefore="$(wc -l gb_unique_rows | awk '{print $1}')"
 #   rowsAfter="$(wc -l gb_unique_rows2 | awk '{print $1}')"
 #   echo -e "$rowsBefore\t$rowsAfter\tRemoved duplicated rows in respect to only chr:pos, GRCh37" >> desc_removed_duplicated_rows
 #   mv gb_unique_rows2 gb_unique_rows
 #   echo "duplicated_chrpos_in_GRCh37" >> afterLiftoverFiltering_executionorder
 # 
  elif [ "${var}" == "duplicated_chrpos_in_GRCh38" ]
  then
    #Filter only on position duplicates (A very hard filter but is good enough for alpha release)
    LC_ALL=C sort -k1,1 ${outfileprefix}gb_unique_rows > ${outfileprefix}gb_unique_rows_sorted
    touch ${outfileprefix}removed_duplicated_rows_GRCh38_hard
    awk -vpre="${outfileprefix}" 'BEGIN{r0="initrowhere"} {var=$1; if(r0!=var){print $0}else{print $0 > pre"removed_duplicated_rows_GRCh38_hard"}; r0=var}' ${outfileprefix}gb_unique_rows_sorted > ${outfileprefix}gb_unique_rows2
    awk -vOFS="\t" '{print $2,"duplicated_rows_GRCh38_hard"}' ${outfileprefix}removed_duplicated_rows_GRCh38_hard >> ${outfileprefix}removed_duplicated_rows
    rowsBefore="$(wc -l ${outfileprefix}gb_unique_rows | awk '{print $1}')"
    rowsAfter="$(wc -l ${outfileprefix}gb_unique_rows2 | awk '{print $1}')"
    echo -e "$rowsBefore\t$rowsAfter\tRemoved duplicated rows in respect to only chr:pos, GRCh38" >> ${outfileprefix}desc_removed_duplicated_rows
    mv ${outfileprefix}gb_unique_rows2 ${outfileprefix}gb_unique_rows
    echo "duplicated_chrpos_in_GRCh38" >> ${outfileprefix}afterLiftoverFiltering_executionorder
  
  elif [ "${var}" == "multiallelics_in_dbsnp" ]
  then
    #Filter on presence of comma in alt allele column, if so, it is by definition a multiallelic in dbsnp
    cp ${outfileprefix}gb_unique_rows ${outfileprefix}gb_unique_rows_sorted
    touch ${outfileprefix}removed_multiallelic_rows
    awk -vFS="\t" -vOFS="\t" -vpre="${outfileprefix}" '{if($5 ~ /,/){print > pre"removed_multiallelic_rows"}else{print $0} }' ${outfileprefix}gb_unique_rows_sorted > ${outfileprefix}gb_unique_rows2
    awk -vOFS="\t" '{print $2,"multiallelic_in_dbsnp"}' ${outfileprefix}removed_multiallelic_rows >> ${outfileprefix}removed_duplicated_rows
    rowsBefore="$(wc -l ${outfileprefix}gb_unique_rows | awk '{print $1}')"
    rowsAfter="$(wc -l ${outfileprefix}gb_unique_rows2 | awk '{print $1}')"
    echo -e "$rowsBefore\t$rowsAfter\tRemoved multi-allelic rows" >> ${outfileprefix}desc_removed_duplicated_rows
    mv ${outfileprefix}gb_unique_rows2 ${outfileprefix}gb_unique_rows
    echo "multiallelics_in_dbsnp" >> ${outfileprefix}afterLiftoverFiltering_executionorder

  elif [ "${var}" == "multiple_rsids_in_dbsnp" ]
  then
    #Filter on presence of multiple rsids
    LC_ALL=C sort -k3,3 ${outfileprefix}gb_unique_rows > ${outfileprefix}gb_unique_rows_sorted
    touch ${outfileprefix}removed_multiple_rsids
    awk -vpre="${outfileprefix}" 'BEGIN{r0="initrowhere"} {var=$3; if(r0!=var){print $0}else{print $0 > pre"removed_multiple_rsids"}; r0=var}' ${outfileprefix}gb_unique_rows_sorted > ${outfileprefix}gb_unique_rows2
    awk -vOFS="\t" '{print $2,"multiple_rsids_in_dbsnp"}' ${outfileprefix}removed_multiple_rsids >> ${outfileprefix}removed_duplicated_rows
    rowsBefore="$(wc -l ${outfileprefix}gb_unique_rows | awk '{print $1}')"
    rowsAfter="$(wc -l ${outfileprefix}gb_unique_rows2 | awk '{print $1}')"
    echo -e "$rowsBefore\t$rowsAfter\tRemoved multiple rsid rows" >> ${outfileprefix}desc_removed_duplicated_rows
    mv ${outfileprefix}gb_unique_rows2 ${outfileprefix}gb_unique_rows
    echo "multiple_rsids_in_dbsnp" >> ${outfileprefix}afterLiftoverFiltering_executionorder
  
  fi

done


if [ "${applyFilter}" == "yes" ]
then
  #resort to same as input, which is first column containing GRCh38 (not, it is likely that future input also will be sorted on first column)
  LC_ALL=C sort -k1,1 ${outfileprefix}gb_unique_rows > ${outfileprefix}gb_unique_rows_sorted
else
  #make output same as input
  mv ${outfileprefix}gb_unique_rows ${outfileprefix}gb_unique_rows_sorted
fi

