liftedandmapped=$1
filtering=$2
outfileprefix=$3


#split comma separated list into bash array
filterArr=($(echo "${filtering}" | awk '{gsub(/ /, "", $0); print}' | awk '{gsub(/,/, "\n", $0); print}' ))


touch ${outfileprefix}desc_removed_duplicated_rows
touch ${outfileprefix}removed_duplicated_rows
touch ${outfileprefix}beforeLiftoverFiltering_executionorder

cp ${liftedandmapped} ${outfileprefix}gb_unique_rows

##check if no filtering will be applied
#if [ "${#filterArr[@]}" -eq 0 ]
#then
#  applyFilter="no"
#else
#  applyFilter="yes"
#fi

LC_ALL=C sort -k1,1 ${outfileprefix}gb_unique_rows > ${outfileprefix}gb_unique_rows_sorted

#loop over bash array applying each correspondinng filtering type in the samee order
for var in ${filterArr[@]}; do

  #the data will be having either chrpos or rsids as first column
  if [ "${var}" == "duplicated_keys" ]
  then
    touch ${outfileprefix}removed_duplicated_rows_keys
    awk 'BEGIN{r0="initrowhere"} {var=$1; if(r0!=var){print $0}else{print $0 > "removed_duplicated_rows_keys"}; r0=var}' ${outfileprefix}gb_unique_rows_sorted > ${outfileprefix}gb_unique_rows2
    awk -vOFS="\t" '{print $2,"removed_duplicated_rows_dbsnpkeys"}' ${outfileprefix}removed_duplicated_rows_keys >> ${outfileprefix}removed_duplicated_rows
    rowsBefore="$(wc -l ${outfileprefix}gb_unique_rows | awk '{print $1}')"
    rowsAfter="$(wc -l ${outfileprefix}gb_unique_rows2 | awk '{print $1}')"
    echo -e "$rowsBefore\t$rowsAfter\tRemoved duplicated rows in respect to chr:pos or rsids" >> ${outfileprefix}desc_removed_duplicated_rows
    mv ${outfileprefix}gb_unique_rows2 ${outfileprefix}gb_unique_rows
    echo "duplicated_dbsnpkey" >> ${outfileprefix}beforeLiftoverFiltering_executionorder
  fi
done


#if [ "${applyFilter}" == "yes" ]
#then
#  #resort to same as input, which is first column containing GRCh38 (not, it is likely that future input also will be sorted on first column)
#  LC_ALL=C sort -k1,1 gb_unique_rows > gb_unique_rows_sorted
#else
#  #make output same as input
#  mv gb_unique_rows gb_unique_rows_sorted
#fi
#
